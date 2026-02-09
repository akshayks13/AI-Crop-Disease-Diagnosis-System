'use client';

import { useEffect, useState } from 'react';
import { Clock, UserCheck, AlertCircle } from 'lucide-react';
import { adminApi } from '@/lib/api';
import { PendingExpert } from '@/types';
import ExpertCard from '@/components/experts/ExpertCard';

export default function ExpertsPage() {
    const [experts, setExperts] = useState<PendingExpert[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [actionLoading, setActionLoading] = useState<string | null>(null);

    useEffect(() => {
        const loadExperts = async () => {
            try {
                const res = await adminApi.getPendingExperts();
                setExperts(res.data.experts || []);
                setError('');
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
            } catch (e: any) {
                setError(e.response?.data?.detail || 'Failed to load pending experts');
            } finally {
                setLoading(false);
            }
        };
        loadExperts();
    }, []);

    const handleApprove = async (id: string) => {
        setActionLoading(id);
        try {
            await adminApi.approveExpert(id);
            setExperts((prev) => prev.filter((e) => e.id !== id));
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
        } catch (e: any) {
            alert(e.response?.data?.detail || 'Failed to approve expert');
        } finally {
            setActionLoading(null);
        }
    };

    const handleReject = async (id: string) => {
        const reason = prompt('Rejection reason (optional):');
        setActionLoading(id);
        try {
            await adminApi.rejectExpert(id, reason || undefined);
            setExperts((prev) => prev.filter((e) => e.id !== id));
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
        } catch (e: any) {
            alert(e.response?.data?.detail || 'Failed to reject expert');
        } finally {
            setActionLoading(null);
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center h-96">
                <div className="flex flex-col items-center gap-4">
                    <div className="w-10 h-10 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin" />
                    <p className="text-sm text-slate-500">Loading experts...</p>
                </div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="bg-red-50 border border-red-200 rounded-xl p-6 text-red-600">
                <div className="flex items-center gap-2">
                    <AlertCircle size={18} />
                    <p className="font-medium">Error loading experts</p>
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
                    <h1 className="text-2xl font-bold text-slate-900">Expert Approval</h1>
                    <p className="text-slate-500 text-sm mt-0.5">Review and approve expert applications</p>
                </div>
                <div className="flex items-center gap-2 px-3 py-2 bg-amber-50 text-amber-700 rounded-lg text-sm font-medium border border-amber-200">
                    <Clock size={16} />
                    {experts.length} pending
                </div>
            </div>

            {experts.length === 0 ? (
                <div className="bg-white rounded-xl border border-slate-200 p-16 text-center">
                    <div className="w-16 h-16 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-5">
                        <UserCheck size={32} className="text-emerald-600" />
                    </div>
                    <h3 className="text-xl font-bold text-slate-900 mb-2">All caught up!</h3>
                    <p className="text-slate-500 text-sm max-w-md mx-auto">No pending expert applications at the moment. New applications will appear here.</p>
                </div>
            ) : (
                <div className="grid gap-4">
                    {experts.map((expert) => (
                        <ExpertCard
                            key={expert.id}
                            expert={expert}
                            isLoading={actionLoading === expert.id}
                            onApprove={handleApprove}
                            onReject={handleReject}
                        />
                    ))}
                </div>
            )}
        </div>
    );
}
