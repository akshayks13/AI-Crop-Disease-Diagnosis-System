'use client';

import { useEffect, useState } from 'react';
import { agronomyApi } from '@/lib/api';
import { Leaf, AlertTriangle, Calendar, Plus, Pencil, Trash2 } from 'lucide-react';

type Tab = 'rules' | 'constraints' | 'patterns';

export default function AgronomyPage() {
    const [activeTab, setActiveTab] = useState<Tab>('rules');
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    // Data states
    const [rules, setRules] = useState<any[]>([]);
    const [constraints, setConstraints] = useState<any[]>([]);
    const [patterns, setPatterns] = useState<any[]>([]);

    useEffect(() => {
        loadData();
    }, [activeTab]);

    const loadData = async () => {
        setLoading(true);
        setError('');
        try {
            if (activeTab === 'rules') {
                const res = await agronomyApi.getDiagnosticRules();
                setRules(res.data);
            } else if (activeTab === 'constraints') {
                const res = await agronomyApi.getTreatmentConstraints();
                setConstraints(res.data);
            } else {
                const res = await agronomyApi.getSeasonalPatterns();
                setPatterns(res.data);
            }
        } catch (e: any) {
            setError(e.response?.data?.detail || 'Failed to load data');
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id: string, type: Tab) => {
        if (!confirm('Are you sure you want to delete this item?')) return;

        try {
            if (type === 'rules') {
                await agronomyApi.deleteDiagnosticRule(id);
            } else if (type === 'constraints') {
                await agronomyApi.deleteTreatmentConstraint(id);
            } else {
                await agronomyApi.deleteSeasonalPattern(id);
            }
            loadData();
        } catch (e: any) {
            alert(e.response?.data?.detail || 'Failed to delete');
        }
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-2xl font-bold text-slate-900">Agronomy Intelligence</h1>
                    <p className="text-slate-500 text-sm mt-1">
                        Manage diagnostic rules, treatment constraints, and seasonal patterns
                    </p>
                </div>
                <button
                    className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors flex items-center gap-2"
                    onClick={() => alert('Create dialog coming soon')}
                >
                    <Plus size={16} />
                    Add New
                </button>
            </div>

            {/* Tabs */}
            <div className="bg-white rounded-xl border border-slate-200 p-1 flex gap-1">
                <button
                    onClick={() => setActiveTab('rules')}
                    className={`flex-1 px-4 py-3 rounded-lg font-medium transition-all flex items-center justify-center gap-2 ${activeTab === 'rules'
                        ? 'bg-green-50 text-green-700 border border-green-200'
                        : 'text-slate-600 hover:bg-slate-50'
                        }`}
                >
                    <Leaf size={18} />
                    Diagnostic Rules ({rules.length})
                </button>
                <button
                    onClick={() => setActiveTab('constraints')}
                    className={`flex-1 px-4 py-3 rounded-lg font-medium transition-all flex items-center justify-center gap-2 ${activeTab === 'constraints'
                        ? 'bg-orange-50 text-orange-700 border border-orange-200'
                        : 'text-slate-600 hover:bg-slate-50'
                        }`}
                >
                    <AlertTriangle size={18} />
                    Treatment Constraints ({constraints.length})
                </button>
                <button
                    onClick={() => setActiveTab('patterns')}
                    className={`flex-1 px-4 py-3 rounded-lg font-medium transition-all flex items-center justify-center gap-2 ${activeTab === 'patterns'
                        ? 'bg-blue-50 text-blue-700 border border-blue-200'
                        : 'text-slate-600 hover:bg-slate-50'
                        }`}
                >
                    <Calendar size={18} />
                    Seasonal Patterns ({patterns.length})
                </button>
            </div>

            {/* Content */}
            {error && (
                <div className="bg-red-50 border border-red-200 rounded-xl p-4 text-red-600">
                    {error}
                </div>
            )}

            <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
                {loading ? (
                    <div className="flex items-center justify-center h-64">
                        <div className="w-8 h-8 border-4 border-green-200 border-t-green-600 rounded-full animate-spin" />
                    </div>
                ) : (
                    <>
                        {activeTab === 'rules' && <RulesTable rules={rules} onDelete={(id) => handleDelete(id, 'rules')} />}
                        {activeTab === 'constraints' && <ConstraintsTable constraints={constraints} onDelete={(id) => handleDelete(id, 'constraints')} />}
                        {activeTab === 'patterns' && <PatternsTable patterns={patterns} onDelete={(id) => handleDelete(id, 'patterns')} />}
                    </>
                )}
            </div>
        </div>
    );
}

function RulesTable({ rules, onDelete }: { rules: any[]; onDelete: (id: string) => void }) {
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
                            <td className="px-6 py-4 text-sm text-slate-600">{rule.disease_id?.substring(0, 8)}...</td>
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
                                >
                                    <Pencil size={16} />
                                </button>
                                <button
                                    onClick={() => onDelete(rule.id)}
                                    className="text-red-600 hover:text-red-700"
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

function ConstraintsTable({ constraints, onDelete }: { constraints: any[]; onDelete: (id: string) => void }) {
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
                                >
                                    <Pencil size={16} />
                                </button>
                                <button
                                    onClick={() => onDelete(constraint.id)}
                                    className="text-red-600 hover:text-red-700"
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

function PatternsTable({ patterns, onDelete }: { patterns: any[]; onDelete: (id: string) => void }) {
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
                                >
                                    <Pencil size={16} />
                                </button>
                                <button
                                    onClick={() => onDelete(pattern.id)}
                                    className="text-red-600 hover:text-red-700"
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
