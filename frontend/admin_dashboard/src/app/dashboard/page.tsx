'use client';

import { useEffect, useState } from 'react';
import { Users, Leaf, HelpCircle, Activity, Database, Clock, TrendingUp } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { adminApi } from '@/lib/api';
import { DashboardData, DailyMetric } from '@/types';

export default function DashboardPage() {
    const [data, setData] = useState<DashboardData | null>(null);
    const [dailyMetrics, setDailyMetrics] = useState<DailyMetric[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetch = async () => {
            try {
                const [dashRes, metricsRes] = await Promise.all([
                    adminApi.getDashboard(),
                    adminApi.getDailyMetrics(14),
                ]);
                setData(dashRes.data);
                setDailyMetrics(metricsRes.data.metrics);
            } catch (e) {
                console.error(e);
            } finally {
                setLoading(false);
            }
        };
        fetch();
    }, []);

    if (loading) return <div className="flex items-center justify-center h-64">Loading...</div>;
    if (!data) return <div className="text-red-500">Error loading data</div>;

    const { metrics, trends } = data;

    return (
        <div>
            {/* Header */}
            <div className="flex justify-between items-center mb-8">
                <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
                <div className={`flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium ${data.system_health === 'healthy' ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'
                    }`}>
                    <Activity size={16} />
                    System {data.system_health}
                </div>
            </div>

            {/* Metrics Grid */}
            <div className="grid grid-cols-4 gap-5 mb-8">
                <div className="bg-gradient-to-br from-green-700 to-green-500 rounded-2xl p-6 text-white shadow-lg">
                    <div className="flex items-center gap-2 text-green-100 text-sm mb-2">
                        <Users size={16} /> Total Users
                    </div>
                    <div className="text-3xl font-bold">{metrics.total_users}</div>
                    <div className="text-green-200 text-sm mt-1">+{trends.recent_signups} this week</div>
                </div>

                <div className="bg-gradient-to-br from-orange-500 to-orange-400 rounded-2xl p-6 text-white shadow-lg">
                    <div className="flex items-center gap-2 text-orange-100 text-sm mb-2">
                        <Leaf size={16} /> Total Diagnoses
                    </div>
                    <div className="text-3xl font-bold">{metrics.total_diagnoses}</div>
                    <div className="text-orange-200 text-sm mt-1">{metrics.diagnoses_today} today</div>
                </div>

                <div className="bg-white rounded-2xl p-6 shadow-md">
                    <div className="flex items-center gap-2 text-gray-500 text-sm mb-2">
                        <HelpCircle size={16} /> Questions
                    </div>
                    <div className="text-3xl font-bold text-gray-900">{metrics.total_questions}</div>
                    <div className="text-gray-500 text-sm mt-1">{trends.open_questions} open</div>
                </div>

                <div className="bg-white rounded-2xl p-6 shadow-md">
                    <div className="flex items-center gap-2 text-gray-500 text-sm mb-2">
                        <Clock size={16} /> Pending Experts
                    </div>
                    <div className="text-3xl font-bold text-gray-900">{metrics.pending_experts}</div>
                    <div className="text-gray-500 text-sm mt-1">Awaiting approval</div>
                </div>
            </div>

            {/* Chart */}
            <div className="bg-white rounded-2xl p-6 shadow-md mb-8">
                <h3 className="flex items-center gap-2 font-semibold text-gray-900 mb-4">
                    <TrendingUp size={18} className="text-green-600" />
                    Activity Trends (14 days)
                </h3>
                <div className="h-72">
                    <ResponsiveContainer width="100%" height="100%">
                        <LineChart data={dailyMetrics}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#eee" />
                            <XAxis dataKey="date" tickFormatter={(v) => new Date(v).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} />
                            <YAxis />
                            <Tooltip />
                            <Line type="monotone" dataKey="diagnoses" stroke="#2E7D32" strokeWidth={2} name="Diagnoses" />
                            <Line type="monotone" dataKey="questions" stroke="#FF9800" strokeWidth={2} name="Questions" />
                            <Line type="monotone" dataKey="signups" stroke="#2196F3" strokeWidth={2} name="Signups" />
                        </LineChart>
                    </ResponsiveContainer>
                </div>
            </div>

            {/* Bottom Grid */}
            <div className="grid grid-cols-2 gap-5">
                <div className="bg-white rounded-2xl p-6 shadow-md">
                    <h3 className="font-semibold text-gray-900 mb-4">User Distribution</h3>
                    <div className="space-y-3">
                        <div className="flex justify-between py-3 border-b border-gray-100">
                            <span className="text-gray-600">Farmers</span>
                            <strong>{metrics.total_farmers}</strong>
                        </div>
                        <div className="flex justify-between py-3 border-b border-gray-100">
                            <span className="text-gray-600">Experts</span>
                            <strong>{metrics.total_experts}</strong>
                        </div>
                        <div className="flex justify-between py-3">
                            <span className="text-gray-600">Resolved Questions</span>
                            <strong>{metrics.resolved_questions}</strong>
                        </div>
                    </div>
                </div>

                <div className="bg-white rounded-2xl p-6 shadow-md">
                    <h3 className="flex items-center gap-2 font-semibold text-gray-900 mb-4">
                        <Database size={18} className="text-blue-600" />
                        Storage
                    </h3>
                    <div className="text-3xl font-bold text-gray-900">{metrics.storage_used_mb.toFixed(1)} MB</div>
                    <div className="text-gray-500 text-sm mt-1">Total storage used</div>
                </div>
            </div>
        </div>
    );
}
