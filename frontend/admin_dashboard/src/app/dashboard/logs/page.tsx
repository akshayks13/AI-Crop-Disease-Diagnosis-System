'use client';

import { useEffect, useState } from 'react';
import { adminApi } from '@/lib/api';
import { SystemLog } from '@/types';
import { formatDistanceToNow } from 'date-fns';
import { AlertCircle, AlertTriangle, Info, XCircle, Filter, ScrollText } from 'lucide-react';

export default function LogsPage() {
    const [logs, setLogs] = useState<SystemLog[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [levelFilter, setLevelFilter] = useState('');

    const loadLogs = async () => {
        setLoading(true);
        try {
            const res = await adminApi.getLogs(1, levelFilter || undefined);
            setLogs(res.data.logs || []);
            setError('');
        } catch (e: any) {
            setError(e.response?.data?.detail || 'Failed to load logs');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { loadLogs(); }, [levelFilter]);

    const levelConfig: Record<string, { bg: string; text: string; icon: any; border: string }> = {
        INFO: { bg: 'bg-indigo-50', text: 'text-indigo-700', icon: Info, border: 'border-indigo-200' },
        WARNING: { bg: 'bg-amber-50', text: 'text-amber-700', icon: AlertTriangle, border: 'border-amber-200' },
        ERROR: { bg: 'bg-red-50', text: 'text-red-700', icon: AlertCircle, border: 'border-red-200' },
        CRITICAL: { bg: 'bg-red-100', text: 'text-red-800', icon: XCircle, border: 'border-red-300' },
    };

    if (error && !loading) {
        return (
            <div className="bg-red-50 border border-red-200 rounded-xl p-6 text-red-600">
                <div className="flex items-center gap-2">
                    <AlertCircle size={18} />
                    <p className="font-medium">Error loading logs</p>
                </div>
                <p className="text-sm mt-1">{error}</p>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-2xl font-bold text-slate-900">System Logs</h1>
                    <p className="text-slate-500 text-sm mt-0.5">Monitor system activity and events</p>
                </div>
                <div className="flex items-center gap-2">
                    <Filter size={16} className="text-slate-400" />
                    <select
                        className="px-3 py-2 bg-white border border-slate-200 rounded-lg text-sm focus:border-indigo-500 outline-none transition-all font-medium text-slate-900"
                        value={levelFilter}
                        onChange={(e) => setLevelFilter(e.target.value)}
                    >
                        <option value="">All Levels</option>
                        <option value="INFO">Info</option>
                        <option value="WARNING">Warning</option>
                        <option value="ERROR">Error</option>
                    </select>
                </div>
            </div>

            {/* Logs List */}
            <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
                {loading ? (
                    <div className="flex items-center justify-center h-64">
                        <div className="w-8 h-8 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin" />
                    </div>
                ) : logs.length === 0 ? (
                    <div className="p-16 text-center">
                        <ScrollText size={40} className="text-slate-300 mx-auto mb-4" />
                        <p className="text-slate-500">No logs found</p>
                    </div>
                ) : (
                    <div className="divide-y divide-slate-100">
                        {logs.map((log) => {
                            const config = levelConfig[log.level] || levelConfig.INFO;
                            const Icon = config.icon;

                            return (
                                <div key={log.id} className="p-4 hover:bg-slate-50 transition-colors">
                                    <div className="flex items-start gap-3">
                                        <div className={`p-2 ${config.bg} rounded-lg flex-shrink-0`}>
                                            <Icon size={16} className={config.text} />
                                        </div>
                                        <div className="flex-1 min-w-0">
                                            <div className="flex items-center gap-2 mb-1">
                                                <span className={`px-2 py-0.5 ${config.bg} ${config.text} rounded text-[10px] font-bold uppercase`}>
                                                    {log.level}
                                                </span>
                                                {log.source && (
                                                    <span className="px-2 py-0.5 bg-slate-100 text-slate-600 rounded text-[10px] font-medium">
                                                        {log.source}
                                                    </span>
                                                )}
                                            </div>
                                            <p className="text-sm text-slate-900">{log.message}</p>
                                        </div>
                                        <div className="text-xs text-slate-400 whitespace-nowrap flex-shrink-0">
                                            {formatDistanceToNow(new Date(log.created_at), { addSuffix: true })}
                                        </div>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                )}
            </div>
        </div>
    );
}
