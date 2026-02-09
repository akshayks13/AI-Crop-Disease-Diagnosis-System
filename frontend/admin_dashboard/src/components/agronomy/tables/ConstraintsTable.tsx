import { Pencil, Trash2 } from 'lucide-react';

interface Constraint {
    id: string;
    treatment_name: string;
    treatment_type: string;
    enforcement_level: string;
    risk_level: string;
}

interface ConstraintsTableProps {
    constraints: Constraint[];
    onDelete: (id: string) => void;
}

export default function ConstraintsTable({ constraints, onDelete }: ConstraintsTableProps) {
    if (constraints.length === 0) {
        return <div className="p-16 text-center text-slate-500">No treatment constraints found</div>;
    }

    return (
        <div className="overflow-x-auto">
            <table className="w-full">
                <thead className="bg-slate-50 border-b border-slate-200">
                    <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase">Treatment</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase">Type</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase">Enforcement</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-slate-600 uppercase">Risk</th>
                        <th className="px-6 py-3 text-right text-xs font-medium text-slate-600 uppercase">Actions</th>
                    </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                    {constraints.map((constraint) => (
                        <tr key={constraint.id} className="hover:bg-slate-50">
                            <td className="px-6 py-4 text-sm font-medium text-slate-900">{constraint.treatment_name}</td>
                            <td className="px-6 py-4">
                                <span className={`px-2 py-1 text-xs font-medium rounded ${constraint.treatment_type === 'chemical'
                                    ? 'bg-orange-100 text-orange-700'
                                    : 'bg-green-100 text-green-700'
                                    }`}>
                                    {constraint.treatment_type}
                                </span>
                            </td>
                            <td className="px-6 py-4 text-sm text-slate-600">{constraint.enforcement_level}</td>
                            <td className="px-6 py-4">
                                <span className={`px-2 py-1 text-xs font-medium rounded ${constraint.risk_level === 'high'
                                    ? 'bg-red-100 text-red-700'
                                    : constraint.risk_level === 'medium'
                                        ? 'bg-yellow-100 text-yellow-700'
                                        : 'bg-blue-100 text-blue-700'
                                    }`}>
                                    {constraint.risk_level}
                                </span>
                            </td>
                            <td className="px-6 py-4 text-right">
                                <button
                                    onClick={() => alert('Edit coming soon')}
                                    className="text-blue-600 hover:text-blue-700 mr-3"
                                    aria-label="Edit constraint"
                                >
                                    <Pencil size={16} />
                                </button>
                                <button
                                    onClick={() => onDelete(constraint.id)}
                                    className="text-red-600 hover:text-red-700"
                                    aria-label="Delete constraint"
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
