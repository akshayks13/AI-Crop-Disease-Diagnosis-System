'use client';

import { useEffect, useState } from 'react';
import { Users, Leaf, HelpCircle, Clock, TrendingUp, ArrowUpRight, Database, Activity } from 'lucide-react';
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
        <div className="space-y-6">
            {/* Header */}
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-2xl font-bold text-slate-900">Dashboard</h1>
                    <p className="text-slate-500 text-sm mt-0.5">Welcome back! Here's what's happening today.</p>
                </div>
                <div className={`flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium ${data.system_health === 'healthy'
                        ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                        : 'bg-amber-50 text-amber-700 border border-amber-200'
                    }`}>
                    <div className={`w-2 h-2 rounded-full animate-pulse ${data.system_health === 'healthy' ? 'bg-emerald-500' : 'bg-amber-500'
                        }`} />
                    System {data.system_health}
                </div>
            </div>

            {/* Metrics Grid */}
            <div className="grid grid-cols-4 gap-5">
                <MetricCard
                    title="Total Users"
                    value={metrics.total_users.toLocaleString()}
                    subtitle={`+${trends.recent_signups} this week`}
                    trend="up"
                    icon={Users}
                    color="indigo"
                />
                <MetricCard
                    title="Diagnoses"
                    value={metrics.total_diagnoses.toLocaleString()}
                    subtitle={`${metrics.diagnoses_today} today`}
                    trend="up"
                    icon={Leaf}
                    color="emerald"
                />
                <MetricCard
                    title="Questions"
                    value={metrics.total_questions.toLocaleString()}
                    subtitle={`${trends.open_questions} open`}
                    trend="neutral"
                    icon={HelpCircle}
                    color="amber"
                />
                <MetricCard
                    title="Pending Experts"
                    value={metrics.pending_experts.toString()}
                    subtitle="Need approval"
                    trend="neutral"
                    icon={Clock}
                    color="purple"
                />
            </div>

            {/* Charts Row */}
            <div className="grid grid-cols-3 gap-5">
                {/* Main Chart */}
                <div className="col-span-2 bg-white rounded-xl p-6 border border-slate-200">
                    <div className="flex items-center justify-between mb-6">
                        <div>
                            <h3 className="text-base font-semibold text-slate-900">Activity Overview</h3>
                            <p className="text-xs text-slate-500 mt-0.5">Diagnoses and questions over time</p>
                        </div>
                        <div className="flex gap-4 text-xs">
                            <div className="flex items-center gap-2">
                                <div className="w-2.5 h-2.5 bg-indigo-500 rounded-full" />
                                <span className="text-slate-600">Diagnoses</span>
                            </div>
                            <div className="flex items-center gap-2">
                                <div className="w-2.5 h-2.5 bg-amber-500 rounded-full" />
                                <span className="text-slate-600">Questions</span>
                            </div>
                        </div>
                    </div>
                    <div className="h-64">
                        {dailyMetrics.length > 0 ? (
                            <ResponsiveContainer width="100%" height="100%">
                                <AreaChart data={dailyMetrics}>
                                    <defs>
                                        <linearGradient id="diagGrad" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor="#6366f1" stopOpacity={0.2} />
                                            <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
                                        </linearGradient>
                                        <linearGradient id="questGrad" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.2} />
                                            <stop offset="95%" stopColor="#f59e0b" stopOpacity={0} />
                                        </linearGradient>
                                    </defs>
                                    <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                                    <XAxis
                                        dataKey="date"
                                        tickFormatter={(v) => new Date(v).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                                        stroke="#94a3b8"
                                        tick={{ fontSize: 11 }}
                                    />
                                    <YAxis stroke="#94a3b8" tick={{ fontSize: 11 }} />
                                    <Tooltip
                                        contentStyle={{
                                            backgroundColor: '#fff',
                                            border: '1px solid #e2e8f0',
                                            borderRadius: '8px',
                                            boxShadow: '0 4px 6px -1px rgba(0,0,0,0.1)',
                                            fontSize: '12px'
                                        }}
                                    />
                                    <Area type="monotone" dataKey="diagnoses" stroke="#6366f1" strokeWidth={2} fill="url(#diagGrad)" />
                                    <Area type="monotone" dataKey="questions" stroke="#f59e0b" strokeWidth={2} fill="url(#questGrad)" />
                                </AreaChart>
                            </ResponsiveContainer>
                        ) : (
                            <div className="flex items-center justify-center h-full text-slate-400 text-sm">
                                No activity data available
                            </div>
                        )}
                    </div>
                </div>

                {/* Quick Stats */}
                <div className="bg-white rounded-xl p-6 border border-slate-200">
                    <h3 className="text-base font-semibold text-slate-900 mb-5">Quick Stats</h3>
                    <div className="space-y-4">
                        <StatRow label="Farmers" value={metrics.total_farmers} color="bg-emerald-500" />
                        <StatRow label="Experts" value={metrics.total_experts} color="bg-indigo-500" />
                        <StatRow label="Resolved Questions" value={metrics.resolved_questions} color="bg-purple-500" />
                        <StatRow label="Storage Used" value={`${metrics.storage_used_mb?.toFixed(1) || 0} MB`} color="bg-amber-500" />
                    </div>

                    <div className="mt-6 p-4 bg-gradient-to-br from-indigo-50 to-purple-50 rounded-xl border border-indigo-100">
                        <div className="flex items-center gap-3">
                            <div className="p-2 bg-indigo-100 rounded-lg">
                                <TrendingUp className="text-indigo-600" size={18} />
                            </div>
                            <div>
                                <p className="text-sm font-semibold text-indigo-800">+{trends.diagnoses_this_week} diagnoses</p>
                                <p className="text-xs text-indigo-600">This week</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}

function MetricCard({ title, value, subtitle, trend, icon: Icon, color }: {
    title: string;
    value: string;
    subtitle: string;
    trend: 'up' | 'down' | 'neutral';
    icon: any;
    color: 'indigo' | 'emerald' | 'amber' | 'purple';
}) {
    const colorClasses = {
        indigo: 'bg-indigo-600',
        emerald: 'bg-emerald-600',
        amber: 'bg-amber-500',
        purple: 'bg-purple-600',
    };

    return (
        <div className="bg-white rounded-xl p-5 border border-slate-200 hover:border-slate-300 transition-colors">
            <div className="flex items-start justify-between mb-4">
                <div className={`p-2.5 ${colorClasses[color]} rounded-lg text-white`}>
                    <Icon size={18} />
                </div>
                {trend === 'up' && <ArrowUpRight className="text-emerald-500" size={18} />}
            </div>
            <p className="text-xs font-medium text-slate-500 uppercase tracking-wide">{title}</p>
            <p className="text-2xl font-bold text-slate-900 mt-1">{value}</p>
            <p className="text-xs text-slate-500 mt-1">{subtitle}</p>
        </div>
    );
}

function StatRow({ label, value, color }: { label: string; value: number | string; color: string }) {
    return (
        <div className="flex items-center justify-between py-2.5 border-b border-slate-100 last:border-0">
            <div className="flex items-center gap-2.5">
                <div className={`w-2 h-2 ${color} rounded-full`} />
                <span className="text-sm text-slate-600">{label}</span>
            </div>
            <span className="text-sm font-semibold text-slate-900">{typeof value === 'number' ? value.toLocaleString() : value}</span>
        </div>
    );
}
