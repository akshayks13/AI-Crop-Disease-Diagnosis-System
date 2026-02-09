import { Pencil, Trash2 } from 'lucide-react';

interface Rule {
    id: string;
    rule_name: string;
    disease_id: string;
    disease_name?: string;
    priority: number;
    is_active: boolean;
}

interface RulesTableProps {
    rules: Rule[];
    onDelete: (id: string) => void;
}

// Format disease_id like "apple_black_rot" to "Apple Black Rot"
function formatDiseaseName(diseaseId: string): string {
    if (!diseaseId) return 'Unknown';
    return diseaseId
        .split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');
}

export default function RulesTable({ rules, onDelete }: RulesTableProps) {
    if (rules.length === 0) {
        return <div className="p-16 text-center text-slate-500">No diagnostic rules found</div>;
    }

    return (
        <div className="overflow-x-auto">
            <table className="w-full">
                <thead className="bg-slate-50 border-b border-slate-200">
                    <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase">Rule Name</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase">Disease</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase">Priority</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase">Status</th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-slate-600 uppercase">Actions</th>
                    </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                    {rules.map((rule) => (
                        <tr key={rule.id} className="hover:bg-slate-50">
                            <td className="px-6 py-4 text-sm font-medium text-slate-900">{rule.rule_name}</td>
                            <td className="px-6 py-4 text-sm text-slate-600">
                                {rule.disease_name || formatDiseaseName(rule.disease_id)}
                            </td>
                            <td className="px-6 py-4 text-sm text-slate-600">{rule.priority}</td>
                            <td className="px-6 py-4">
                                <span className={`px-2 py-1 text-xs font-medium rounded ${rule.is_active
                                    ? 'bg-green-100 text-green-700'
                                    : 'bg-slate-100 text-slate-600'
                                    }`}>
                                    {rule.is_active ? 'Active' : 'Inactive'}
                                </span>
                            </td>
                            <td className="px-6 py-4 text-right">
                                <button
                                    onClick={() => alert('Edit coming soon')}
                                    className="text-blue-600 hover:text-blue-700 mr-3"
                                    aria-label="Edit rule"
                                >
                                    <Pencil size={16} />
                                </button>
                                <button
                                    onClick={() => onDelete(rule.id)}
                                    className="text-red-600 hover:text-red-700"
                                    aria-label="Delete rule"
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
