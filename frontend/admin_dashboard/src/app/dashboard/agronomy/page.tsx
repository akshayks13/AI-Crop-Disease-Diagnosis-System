'use client';

import { useEffect, useState } from 'react';
import { agronomyApi } from '@/lib/api';
import { Leaf, AlertTriangle, Calendar, Plus } from 'lucide-react';
import CreateModal from '@/components/agronomy/CreateModal';
import RulesTable from '@/components/agronomy/tables/RulesTable';
import ConstraintsTable from '@/components/agronomy/tables/ConstraintsTable';
import PatternsTable from '@/components/agronomy/tables/PatternsTable';

type Tab = 'rules' | 'constraints' | 'patterns';

export default function AgronomyPage() {
    const [activeTab, setActiveTab] = useState<Tab>('rules');
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [showModal, setShowModal] = useState(false);

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

    const handleCreate = async (data: any) => {
        try {
            if (activeTab === 'rules') {
                await agronomyApi.createDiagnosticRule(data);
            } else if (activeTab === 'constraints') {
                await agronomyApi.createTreatmentConstraint(data);
            } else {
                await agronomyApi.createSeasonalPattern(data);
            }
            setShowModal(false);
            loadData();
        } catch (e: any) {
            alert(e.response?.data?.detail || 'Failed to create');
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
                    onClick={() => setShowModal(true)}
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

            {/* Create Modal */}
            {showModal && (
                <CreateModal
                    type={activeTab}
                    onClose={() => setShowModal(false)}
                    onCreate={handleCreate}
                />
            )}
        </div>
    );
}
