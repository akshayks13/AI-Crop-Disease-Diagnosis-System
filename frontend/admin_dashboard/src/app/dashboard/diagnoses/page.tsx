'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import { Search, AlertCircle, Leaf, Sprout, Filter, Info, Maximize2, X, Calendar, User, Eye } from 'lucide-react';
import { adminApi } from '@/lib/api';

interface Diagnosis {
    id: string;
    created_at: string;
    media_path: string;
    crop_type: string | null;
    disease: string;
    severity: string;
    confidence: number;
    user: {
        name: string;
        email: string;
    };
    location: string | null;
}

export default function DiagnosesPage() {
    const [diagnoses, setDiagnoses] = useState<Diagnosis[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [filters, setFilters] = useState({ disease: '', crop: '' });
    const [page, setPage] = useState(1);
    const [selectedImage, setSelectedImage] = useState<string | null>(null);

    const loadDiagnoses = async () => {
        setLoading(true);
        try {
            const res = await adminApi.getDiagnoses(page, filters);
            setDiagnoses(res.data.diagnoses || []);
            setError('');
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
        } catch (e: any) {
            setError(e.response?.data?.detail || 'Failed to load diagnoses');
        } finally {
            setLoading(false);
        }
    };

    // eslint-disable-next-line react-hooks/exhaustive-deps
    useEffect(() => { loadDiagnoses(); }, [page]);

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault();
        setPage(1); // Reset to page 1 on filter change
        loadDiagnoses();
    };

    const getSeverityColor = (severity: string) => {
        switch (severity?.toLowerCase()) {
            case 'high':
            case 'severe':
                return 'bg-red-50 text-red-700 border-red-200';
            case 'moderate':
                return 'bg-amber-50 text-amber-700 border-amber-200';
            default:
                return 'bg-emerald-50 text-emerald-700 border-emerald-200';
        }
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div>
                <h1 className="text-2xl font-bold text-slate-900">Diagnoses & Reports</h1>
                <p className="text-slate-500 text-sm mt-0.5">Monitor AI diagnosis activity</p>
            </div>

            {/* Filter Bar */}
            <div className="bg-white rounded-xl border border-slate-200 p-4">
                <form onSubmit={handleSearch} className="flex gap-3 flex-wrap md:flex-nowrap">
                    <div className="relative flex-1 min-w-[200px]">
                        <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                        <input
                            type="text"
                            placeholder="Filter by Disease..."
                            className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:border-indigo-500 focus:bg-white focus:ring-2 focus:ring-indigo-100 outline-none transition-all text-slate-900 placeholder:text-slate-400"
                            value={filters.disease}
                            onChange={(e) => setFilters({ ...filters, disease: e.target.value })}
                        />
                    </div>
                    <div className="relative flex-1 min-w-[200px]">
                        <Sprout className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                        <input
                            type="text"
                            placeholder="Filter by Crop..."
                            className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:border-indigo-500 focus:bg-white focus:ring-2 focus:ring-indigo-100 outline-none transition-all text-slate-900 placeholder:text-slate-400"
                            value={filters.crop}
                            onChange={(e) => setFilters({ ...filters, crop: e.target.value })}
                        />
                    </div>
                    <button
                        type="submit"
                        className="px-5 py-2.5 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition-all flex items-center gap-2"
                    >
                        <Filter size={16} />
                        Apply
                    </button>
                    <button
                        type="button"
                        onClick={loadDiagnoses}
                        className="px-4 py-2.5 bg-slate-100 text-slate-600 rounded-lg text-sm font-medium hover:bg-slate-200 transition-all"
                    >
                        Refresh
                    </button>
                </form>
            </div>

            {/* Content Area */}
            {error && (
                <div className="bg-red-50 border border-red-200 rounded-xl p-4 text-red-600 flex items-center gap-3">
                    <AlertCircle size={20} />
                    <p>{error}</p>
                </div>
            )}

            <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
                {loading ? (
                    <div className="flex items-center justify-center h-64">
                        <div className="w-8 h-8 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin" />
                    </div>
                ) : diagnoses.length === 0 ? (
                    <div className="p-16 text-center">
                        <Leaf size={40} className="text-slate-300 mx-auto mb-4" />
                        <p className="text-slate-500">No diagnoses found matching your criteria</p>
                    </div>
                ) : (
                    <table className="w-full">
                        <thead>
                            <tr className="bg-slate-50 border-b border-slate-200">
                                <th className="px-5 py-3 text-left text-[10px] font-semibold text-slate-500 uppercase tracking-wider">Scan</th>
                                <th className="px-5 py-3 text-left text-[10px] font-semibold text-slate-500 uppercase tracking-wider">Disease / Issue</th>
                                <th className="px-5 py-3 text-left text-[10px] font-semibold text-slate-500 uppercase tracking-wider">Status</th>
                                <th className="px-5 py-3 text-left text-[10px] font-semibold text-slate-500 uppercase tracking-wider">Farmer</th>
                                <th className="px-5 py-3 text-left text-[10px] font-semibold text-slate-500 uppercase tracking-wider">Date</th>
                                <th className="px-5 py-3 text-right text-[10px] font-semibold text-slate-500 uppercase tracking-wider">Action</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                            {diagnoses.map((item) => (
                                <tr key={item.id} className="hover:bg-slate-50 transition-colors">
                                    <td className="px-5 py-3">
                                        <div
                                            className="relative w-12 h-12 rounded-lg overflow-hidden bg-slate-100 border border-slate-200 cursor-pointer group"
                                            onClick={() => setSelectedImage(`${process.env.NEXT_PUBLIC_API_URL}${item.media_path}`)}
                                        >
                                            <Image
                                                src={item.media_path?.startsWith('http') ? item.media_path : `${process.env.NEXT_PUBLIC_API_URL}${item.media_path}`}
                                                alt={item.disease}
                                                fill
                                                unoptimized
                                                className="object-cover group-hover:scale-110 transition-transform"
                                            />
                                            <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors flex items-center justify-center">
                                                <Maximize2 size={12} className="text-white opacity-0 group-hover:opacity-100" />
                                            </div>
                                        </div>
                                    </td>
                                    <td className="px-5 py-3">
                                        <p className="font-semibold text-slate-900">{item.disease}</p>
                                        <p className="text-xs text-slate-500">{item.crop_type || 'Unknown Crop'}</p>
                                    </td>
                                    <td className="px-5 py-3">
                                        <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 ${getSeverityColor(item.severity)} rounded-md text-xs font-medium border`}>
                                            {item.severity || 'Unknown'}
                                            <span className="w-1 h-1 rounded-full bg-current opacity-50" />
                                            {(item.confidence * 100).toFixed(0)}%
                                        </span>
                                    </td>
                                    <td className="px-5 py-3">
                                        <div className="flex items-center gap-2">
                                            <div className="w-6 h-6 bg-indigo-100 text-indigo-700 rounded-full flex items-center justify-center text-xs font-bold">
                                                {item.user.name.charAt(0)}
                                            </div>
                                            <span className="text-sm text-slate-700">{item.user.name}</span>
                                        </div>
                                    </td>
                                    <td className="px-5 py-3">
                                        <div className="flex items-center gap-1.5 text-xs text-slate-500">
                                            <Calendar size={12} />
                                            {new Date(item.created_at).toLocaleDateString()}
                                        </div>
                                    </td>
                                    <td className="px-5 py-3 text-right">
                                        <button
                                            className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-white border border-slate-200 text-slate-600 rounded-md text-xs font-medium hover:bg-slate-50 hover:text-indigo-600 transition-all"
                                            onClick={() => setSelectedImage(`${process.env.NEXT_PUBLIC_API_URL}${item.media_path}`)}
                                        >
                                            <Eye size={14} /> View
                                        </button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>

            {/* Image Zoom Modal */}
            {selectedImage && (
                <div
                    className="fixed inset-0 z-50 bg-black/95 flex items-center justify-center p-4 animate-in fade-in duration-200"
                    onClick={() => setSelectedImage(null)}
                >
                    <button
                        className="absolute top-6 right-6 text-white/70 hover:text-white p-2 rounded-full hover:bg-white/10 transition-colors"
                        onClick={() => setSelectedImage(null)}
                    >
                        <X size={32} />
                    </button>
                    <div className="relative w-full max-w-5xl h-[85vh]">
                        <Image
                            src={selectedImage}
                            alt="Zoom"
                            fill
                            unoptimized
                            className="object-contain"
                        />
                    </div>
                </div>
            )}
        </div>
    );
}
