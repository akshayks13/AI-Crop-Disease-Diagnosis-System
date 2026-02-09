import { Pencil, Trash2 } from 'lucide-react';

interface Pattern {
    id: string;
    crop_id: string;
    disease_id: string;
    season: string;
    region?: string;
    likelihood_score: number;
}

interface PatternsTableProps {
    patterns: Pattern[];
    onDelete: (id: string) => void;
}

export default function PatternsTable({ patterns, onDelete }: PatternsTableProps) {
    if (patterns.length === 0) {
        return <div className="p-16 text-center text-slate-500">No seasonal patterns found</div>;
    }

    return (
        <div className="overflow-x-auto">
            <table className="w-full">
                <thead className="bg-slate-50 border-b border-slate-200">
                    <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase">Crop</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase">Disease</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase">Season</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase">Region</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase">Likelihood</th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-slate-600 uppercase">Actions</th>
                    </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                    {patterns.map((pattern) => (
                        <tr key={pattern.id} className="hover:bg-slate-50">
                            <td className="px-6 py-4 text-sm text-slate-600">{pattern.crop_id?.substring(0, 8)}...</td>
                            <td className="px-6 py-4 text-sm text-slate-600">{pattern.disease_id?.substring(0, 8)}...</td>
                            <td className="px-6 py-4 text-sm font-medium text-slate-900">{pattern.season}</td>
                            <td className="px-6 py-4 text-sm text-slate-600">{pattern.region || 'General'}</td>
                            <td className="px-6 py-4">
                                <div className="flex items-center gap-2">
                                    <div className="w-24 bg-slate-200 rounded-full h-2">
                                        <div
                                            className="bg-blue-600 h-2 rounded-full"
                                            style={{ width: `${(pattern.likelihood_score || 0) * 100}%` }}
                                        />
                                    </div>
                                    <span className="text-sm text-slate-600">
                                        {((pattern.likelihood_score || 0) * 100).toFixed(0)}%
                                    </span>
                                </div>
                            </td>
                            <td className="px-6 py-4 text-right">
                                <button
                                    onClick={() => alert('Edit coming soon')}
                                    className="text-blue-600 hover:text-blue-700 mr-3"
                                    aria-label="Edit pattern"
                                >
                                    <Pencil size={16} />
                                </button>
                                <button
                                    onClick={() => onDelete(pattern.id)}
                                    className="text-red-600 hover:text-red-700"
                                    aria-label="Delete pattern"
                                >
                                    <Trash2 size={16} />
                                </button>
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
}
