'use client';

import { useEffect, useState } from 'react';
import { Users, Leaf, HelpCircle, Clock, TrendingUp, ArrowUpRight } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { adminApi } from '@/lib/api';
import { DashboardData, DailyMetric } from '@/types';

export default function DashboardPage() {
    const [data, setData] = useState<DashboardData | null>(null);
    const [dailyMetrics, setDailyMetrics] = useState<DailyMetric[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    useEffect(() => {
        const fetchData = async () => {
            try {
                const [dashRes, metricsRes] = await Promise.all([
                    adminApi.getDashboard(),
                    adminApi.getDailyMetrics(14),
                ]);
                setData(dashRes.data);
                setDailyMetrics(metricsRes.data.metrics || []);
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
            } catch (e: any) {
                setError(e.response?.data?.detail || 'Failed to load dashboard data');
            } finally {
                setLoading(false);
            }
        };
        fetchData();
    }, []);

    if (loading) {
        return (
            <div className="flex items-center justify-center h-96">
                <div className="flex flex-col items-center gap-4">
                    <div className="w-10 h-10 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin" />
                    <p className="text-sm text-slate-500">Loading dashboard...</p>
                </div>
            </div>
        );
    }

    if (error || !data) {
        return (
            <div className="bg-red-50 border border-red-200 rounded-xl p-6 text-red-600">
                <p className="font-medium">Error loading dashboard</p>
                <p className="text-sm mt-1">{error || 'Please check your connection and try again.'}</p>
            </div>
        );
    }

    const { metrics, trends } = data;

    return (
        <div className="space-y-8">
            {/* Header */}
            <div>
                <h1 className="text-3xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-slate-900 to-slate-700">
                    Dashboard Overview
                </h1>
                <p className="text-slate-500 mt-1 font-medium">Real-time insights into your agricultural network.</p>
            </div>

            {/* System Status Banner */}
            <div className={`flex items-center justify-between p-4 rounded-xl border ${data.system_health === 'healthy'
                    ? 'bg-gradient-to-r from-emerald-50 to-teal-50 border-emerald-100'
                    : 'bg-gradient-to-r from-amber-50 to-orange-50 border-amber-100'
                }`}>
                <div className="flex items-center gap-3">
                    <div className={`p-2 rounded-lg ${data.system_health === 'healthy' ? 'bg-emerald-100 text-emerald-600' : 'bg-amber-100 text-amber-600'
                        }`}>
                        <TrendingUp size={20} />
                    </div>
                    <div>
                        <p className={`font-bold ${data.system_health === 'healthy' ? 'text-emerald-900' : 'text-amber-900'
                            }`}>System Operational</p>
                        <p className="text-sm text-slate-600">All services are running normally.</p>
                    </div>
                </div>
                <div className={`px-4 py-1.5 rounded-full text-sm font-bold shadow-sm ${data.system_health === 'healthy' ? 'bg-white text-emerald-600' : 'bg-white text-amber-600'
                    }`}>
                    {data.system_health === 'healthy' ? 'HEALTHY' : 'ATTENTION'}
                </div>
            </div>

            {/* Main Metrics */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <MetricCard
                    title="Total Farmers"
                    value={metrics.total_users.toLocaleString()}
                    subtitle={`+${trends.recent_signups} new this week`}
                    icon={Users}
                    gradient="from-blue-500 to-indigo-600"
                />
                <MetricCard
                    title="Total Diagnoses"
                    value={metrics.total_diagnoses.toLocaleString()}
                    subtitle={`${metrics.diagnoses_today} processed today`}
                    icon={Leaf}
                    gradient="from-emerald-500 to-teal-600"
                />
                <MetricCard
                    title="Questions Asked"
                    value={metrics.total_questions.toLocaleString()}
                    subtitle={`${trends.open_questions} pending answers`}
                    icon={HelpCircle}
                    gradient="from-amber-400 to-orange-500"
                />
                <MetricCard
                    title="Pending Experts"
                    value={metrics.pending_experts.toString()}
                    subtitle="Awaiting verification"
                    icon={Clock}
                    gradient="from-purple-500 to-pink-600"
                />
            </div>

            {/* Charts & Secondary Stats */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Chart Section */}
                <div className="lg:col-span-2 bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
                    <div className="flex items-center justify-between mb-8">
                        <div>
                            <h3 className="text-lg font-bold text-slate-800">Activity Trends</h3>
                            <p className="text-sm text-slate-500">Last 14 days performance</p>
                        </div>
                    </div>
                    <div className="h-[300px]">
                        {dailyMetrics.length > 0 ? (
                            <ResponsiveContainer width="100%" height="100%">
                                <AreaChart data={dailyMetrics}>
                                    <defs>
                                        <linearGradient id="colorDiagnoses" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor="#10b981" stopOpacity={0.1} />
                                            <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                                        </linearGradient>
                                        <linearGradient id="colorQuestions" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.1} />
                                            <stop offset="95%" stopColor="#f59e0b" stopOpacity={0} />
                                        </linearGradient>
                                    </defs>
                                    <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                                    <XAxis
                                        dataKey="date"
                                        tickFormatter={(v) => new Date(v).toLocaleDateString('en-US', { day: '2-digit', month: 'short' })}
                                        stroke="#94a3b8"
                                        fontSize={12}
                                        tickLine={false}
                                        axisLine={false}
                                    />
                                    <YAxis
                                        stroke="#94a3b8"
                                        fontSize={12}
                                        tickLine={false}
                                        axisLine={false}
                                    />
                                    <Tooltip
                                        contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1)' }}
                                    />
                                    <Area type="monotone" dataKey="diagnoses" stroke="#10b981" strokeWidth={3} fillOpacity={1} fill="url(#colorDiagnoses)" />
                                    <Area type="monotone" dataKey="questions" stroke="#f59e0b" strokeWidth={3} fillOpacity={1} fill="url(#colorQuestions)" />
                                </AreaChart>
                            </ResponsiveContainer>
                        ) : (
                            <div className="flex flex-col items-center justify-center h-full text-slate-400">
                                <TrendingUp size={32} className="mb-2 opacity-50" />
                                <p>No trend data available yet</p>
                            </div>
                        )}
                    </div>
                </div>

                {/* Side Stats */}
                <div className="space-y-6">
                    <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100">
                        <h3 className="text-lg font-bold text-slate-800 mb-4">Platform Stats</h3>
                        <div className="space-y-4">
                            <StatRow label="Verified Experts" value={metrics.total_experts} icon={Users} color="text-indigo-600" bg="bg-indigo-50" />
                            <StatRow label="Resolved Questions" value={metrics.resolved_questions} icon={HelpCircle} color="text-emerald-600" bg="bg-emerald-50" />
                            <div className="pt-4 border-t border-slate-50">
                                <div className="flex justify-between text-sm mb-1">
                                    <span className="font-medium text-slate-600">Storage Usage</span>
                                    <span className="text-slate-900 font-bold">{metrics.storage_used_mb?.toFixed(0) || 0} MB</span>
                                </div>
                                <div className="w-full bg-slate-100 rounded-full h-2">
                                    <div className="bg-slate-800 h-2 rounded-full" style={{ width: '15%' }}></div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div className="bg-gradient-to-br from-indigo-900 to-slate-900 rounded-2xl p-6 text-white shadow-lg">
                        <h3 className="text-lg font-bold opacity-90">Weekly Growth</h3>
                        <div className="mt-4 flex items-end gap-2">
                            <span className="text-4xl font-bold">+{trends.diagnoses_this_week}</span>
                            <span className="text-sm opacity-70 mb-1.5">diagnoses</span>
                        </div>
                        <p className="text-sm opacity-60 mt-1">Increasing activity across the platform.</p>
                    </div>
                </div>
            </div>
        </div>
    );
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function MetricCard({ title, value, subtitle, icon: Icon, gradient }: { title: string, value: string, subtitle: string, icon: any, gradient: string }) {
    return (
        <div className="relative overflow-hidden bg-white p-6 rounded-2xl shadow-sm border border-slate-100 group hover:shadow-md transition-all">
            <div className={`absolute top-0 right-0 w-24 h-24 bg-gradient-to-br ${gradient} opacity-10 rounded-bl-full -mr-4 -mt-4 transition-transform group-hover:scale-110`}></div>

            <div className="relative">
                <div className={`w-12 h-12 rounded-xl bg-gradient-to-br ${gradient} flex items-center justify-center text-white mb-4 shadow-lg shadow-black/5`}>
                    <Icon size={22} />
                </div>
                <div>
                    <h3 className="text-slate-500 font-medium text-sm">{title}</h3>
                    <p className="text-3xl font-bold text-slate-800 mt-1 tracking-tight">{value}</p>
                    <p className={`text-sm mt-1 font-medium bg-gradient-to-r ${gradient} bg-clip-text text-transparent`}>
                        {subtitle}
                    </p>
                </div>
            </div>
        </div>
    );
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function StatRow({ label, value, icon: Icon, color, bg }: { label: string, value: string | number, icon: any, color: string, bg: string }) {
    return (
        <div className="flex items-center justify-between group cursor-default">
            <div className="flex items-center gap-3">
                <div className={`p-2 rounded-lg ${bg} ${color} transition-colors group-hover:scale-105`}>
                    <Icon size={18} />
                </div>
                <span className="font-medium text-slate-600">{label}</span>
            </div>
            <span className="font-bold text-slate-900">{value}</span>
        </div>
    );
}
