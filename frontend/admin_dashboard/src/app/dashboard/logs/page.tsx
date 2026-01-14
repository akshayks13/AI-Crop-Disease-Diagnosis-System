'use client';

import { useEffect, useState } from 'react';
import { adminApi } from '@/lib/api';
import { SystemLog } from '@/types';
import { formatDistanceToNow } from 'date-fns';

const levelColors: Record<string, string> = {
    INFO: 'text-green-600',
    WARNING: 'text-orange-600',
    ERROR: 'text-red-600',
    CRITICAL: 'text-red-800',
};

export default function LogsPage() {
    const [logs, setLogs] = useState<SystemLog[]>([]);
    const [loading, setLoading] = useState(true);
    const [levelFilter, setLevelFilter] = useState('');

    const loadLogs = async () => {
        setLoading(true);
        try {
            const res = await adminApi.getLogs(1, levelFilter || undefined);
            setLogs(res.data.logs);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { loadLogs(); }, [levelFilter]);

    return (
        <div>
            <div className="flex justify-between items-center mb-8">
                <h1 className="text-2xl font-bold text-gray-900">System Logs</h1>
                <select
                    className="px-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-green-500 outline-none"
                    value={levelFilter}
                    onChange={(e) => setLevelFilter(e.target.value)}
                >
                    <option value="">All Levels</option>
                    <option value="INFO">INFO</option>
                    <option value="WARNING">WARNING</option>
                    <option value="ERROR">ERROR</option>
                </select>
            </div>

            <div className="bg-white rounded-2xl shadow-md overflow-hidden">
                {loading ? (
                    <div className="p-8 text-center">Loading...</div>
                ) : logs.length === 0 ? (
                    <div className="p-12 text-center text-gray-500">No logs found</div>
                ) : (
                    <table className="w-full">
                        <thead className="bg-gray-50">
                            <tr>
                                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase">Level</th>
                                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase">Message</th>
                                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase">Source</th>
                                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase">Time</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {logs.map((log) => (
                                <tr key={log.id} className="hover:bg-gray-50">
                                    <td className="px-6 py-4">
                                        <span className={`font-semibold ${levelColors[log.level] || 'text-gray-600'}`}>
                                            {log.level}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4 text-gray-600">{log.message}</td>
                                    <td className="px-6 py-4 text-gray-500">{log.source || '-'}</td>
                                    <td className="px-6 py-4 text-gray-400 text-sm">
                                        {formatDistanceToNow(new Date(log.created_at), { addSuffix: true })}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>
        </div>
    );
}
