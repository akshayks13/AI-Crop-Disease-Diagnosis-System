'use client';

import { useEffect, useState } from 'react';
import { Check, X } from 'lucide-react';
import { adminApi } from '@/lib/api';
import { PendingExpert } from '@/types';

export default function ExpertsPage() {
    const [experts, setExperts] = useState<PendingExpert[]>([]);
    const [loading, setLoading] = useState(true);

    const loadExperts = async () => {
        try {
            const res = await adminApi.getPendingExperts();
            setExperts(res.data.experts);
        } catch (e) {
            console.error(e);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { loadExperts(); }, []);

    const handleApprove = async (id: string) => {
        try {
            await adminApi.approveExpert(id);
            setExperts((prev) => prev.filter((e) => e.id !== id));
        } catch (e) {
            alert('Failed to approve');
        }
    };

    const handleReject = async (id: string) => {
        const reason = prompt('Rejection reason (optional):');
        try {
            await adminApi.rejectExpert(id, reason || undefined);
            setExperts((prev) => prev.filter((e) => e.id !== id));
        } catch (e) {
            alert('Failed to reject');
        }
    };

    if (loading) return <div className="flex items-center justify-center h-64">Loading...</div>;

    return (
        <div>
            <div className="flex justify-between items-center mb-8">
                <h1 className="text-2xl font-bold text-gray-900">Expert Approval</h1>
                <span className="px-4 py-2 bg-orange-100 text-orange-700 rounded-full text-sm font-medium">
                    {experts.length} pending
                </span>
            </div>

            {experts.length === 0 ? (
                <div className="bg-white rounded-2xl shadow-md p-12 text-center">
                    <Check size={48} className="text-green-500 mx-auto mb-4" />
                    <h3 className="text-xl font-semibold">All caught up!</h3>
                    <p className="text-gray-500">No pending expert applications</p>
                </div>
            ) : (
                <div className="bg-white rounded-2xl shadow-md overflow-hidden">
                    <table className="w-full">
                        <thead className="bg-gray-50">
                            <tr>
                                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase">Name</th>
                                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase">Email</th>
                                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase">Expertise</th>
                                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase">Qualification</th>
                                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase">Experience</th>
                                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {experts.map((expert) => (
                                <tr key={expert.id} className="hover:bg-gray-50">
                                    <td className="px-6 py-4 font-medium">{expert.full_name}</td>
                                    <td className="px-6 py-4 text-gray-600">{expert.email}</td>
                                    <td className="px-6 py-4 text-gray-600">{expert.expertise_domain}</td>
                                    <td className="px-6 py-4 text-gray-600">{expert.qualification}</td>
                                    <td className="px-6 py-4 text-gray-600">{expert.experience_years} years</td>
                                    <td className="px-6 py-4">
                                        <div className="flex gap-2">
                                            <button
                                                onClick={() => handleApprove(expert.id)}
                                                className="flex items-center gap-1 px-3 py-2 bg-green-600 text-white rounded-lg text-sm font-medium hover:bg-green-700 transition"
                                            >
                                                <Check size={14} /> Approve
                                            </button>
                                            <button
                                                onClick={() => handleReject(expert.id)}
                                                className="flex items-center gap-1 px-3 py-2 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700 transition"
                                            >
                                                <X size={14} /> Reject
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    );
}
