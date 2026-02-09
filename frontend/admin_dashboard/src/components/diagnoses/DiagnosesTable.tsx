import Image from 'next/image';
import { Maximize2, Calendar, Eye } from 'lucide-react';

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

interface DiagnosesTableProps {
    diagnoses: Diagnosis[];
    loading: boolean;
    onImageClick: (imagePath: string) => void;
}

export default function DiagnosesTable({ diagnoses, loading, onImageClick }: DiagnosesTableProps) {
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

    if (loading) {
        return (
            <div className="flex items-center justify-center h-64">
                <div className="w-8 h-8 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin" />
            </div>
        );
    }

    if (diagnoses.length === 0) {
        return (
            <div className="p-16 text-center">
                <div className="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <span className="text-2xl">🌾</span>
                </div>
                <p className="text-slate-500">No diagnoses found matching your criteria</p>
            </div>
        );
    }

    return (
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
                                onClick={() => onImageClick(`${process.env.NEXT_PUBLIC_API_URL}${item.media_path}`)}
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
                                onClick={() => onImageClick(`${process.env.NEXT_PUBLIC_API_URL}${item.media_path}`)}
                            >
                                <Eye size={14} /> View
                            </button>
                        </td>
                    </tr>
                ))}
            </tbody>
        </table>
    );
}
