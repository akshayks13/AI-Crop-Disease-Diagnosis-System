'use client';

import { useEffect, useState } from 'react';
import { Check, X, Mail, Briefcase, GraduationCap, Clock, UserCheck, AlertCircle } from 'lucide-react';
import { adminApi } from '@/lib/api';
import { PendingExpert } from '@/types';

export default function ExpertsPage() {
    const [experts, setExperts] = useState<PendingExpert[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [actionLoading, setActionLoading] = useState<string | null>(null);

    const loadExperts = async () => {
        try {
            const res = await adminApi.getPendingExperts();
            setExperts(res.data.experts || []);
            setError('');
        } catch (e: any) {
            setError(e.response?.data?.detail || 'Failed to load pending experts');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { loadExperts(); }, []);

    const handleApprove = async (id: string) => {
        setActionLoading(id);
        try {
            await adminApi.approveExpert(id);
            setExperts((prev) => prev.filter((e) => e.id !== id));
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
                        <div key={expert.id} className="bg-white rounded-xl border border-slate-200 p-5 hover:border-slate-300 transition-colors">
                            <div className="flex items-start gap-5">
                                {/* Avatar */}
                                <div className="w-14 h-14 bg-gradient-to-br from-indigo-500 to-purple-600 rounded-xl flex items-center justify-center text-white text-lg font-bold flex-shrink-0">
                                    {expert.full_name.split(' ').map(n => n[0]).join('')}
                                </div>

                                {/* Details */}
                                <div className="flex-1 min-w-0">
                                    <div className="flex items-start justify-between">
                                        <div>
                                            <h3 className="text-base font-bold text-slate-900">{expert.full_name}</h3>
                                            <div className="flex items-center gap-1.5 text-slate-500 text-sm mt-0.5">
                                                <Mail size={13} />
                                                {expert.email}
                                            </div>
                                        </div>
                                        <span className="px-2.5 py-1 bg-amber-100 text-amber-700 rounded-md text-xs font-medium">
                                            Pending
                                        </span>
                                    </div>

                                    <div className="grid grid-cols-3 gap-4 mt-4">
                                        <InfoItem icon={Briefcase} label="Expertise" value={expert.expertise_domain || 'N/A'} color="indigo" />
                                        <InfoItem icon={GraduationCap} label="Qualification" value={expert.qualification || 'N/A'} color="purple" />
                                        <InfoItem icon={Clock} label="Experience" value={`${expert.experience_years || 0} years`} color="emerald" />
                                    </div>
                                </div>

                                {/* Actions */}
                                <div className="flex flex-col gap-2 flex-shrink-0">
                                    <button
                                        onClick={() => handleApprove(expert.id)}
                                        disabled={actionLoading === expert.id}
                                        className="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition-all disabled:opacity-50"
                                    >
                                        {actionLoading === expert.id ? (
                                            <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                        ) : (
                                            <Check size={16} />
                                        )}
                                        Approve
                                    </button>
                                    <button
                                        onClick={() => handleReject(expert.id)}
                                        disabled={actionLoading === expert.id}
                                        className="flex items-center gap-2 px-4 py-2 bg-white border border-red-200 text-red-600 rounded-lg text-sm font-medium hover:bg-red-50 transition-all disabled:opacity-50"
                                    >
                                        <X size={16} /> Reject
                                    </button>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}

function InfoItem({ icon: Icon, label, value, color }: { icon: any; label: string; value: string; color: string }) {
    const colors: Record<string, string> = {
        indigo: 'bg-indigo-50 text-indigo-600',
        purple: 'bg-purple-50 text-purple-600',
        emerald: 'bg-emerald-50 text-emerald-600',
    };

    return (
        <div className="flex items-center gap-2.5">
            <div className={`p-1.5 rounded-md ${colors[color]}`}>
                <Icon size={14} />
            </div>
            <div className="min-w-0">
                <p className="text-[10px] text-slate-500 uppercase tracking-wide">{label}</p>
                <p className="text-sm font-medium text-slate-900 truncate">{value}</p>
            </div>
        </div>
    );
}
