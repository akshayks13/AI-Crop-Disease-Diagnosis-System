'use client';

import { useState } from 'react';

interface FormProps {
    formData: any;
    setFormData: (data: any) => void;
}

export default function DiagnosticRuleForm({ formData, setFormData }: FormProps) {
    return (
        <>
            <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Disease ID</label>
                <input
                    type="text"
                    required
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    value={formData.disease_id || ''}
                    onChange={(e) => setFormData({ ...formData, disease_id: e.target.value })}
                    placeholder="UUID of the disease"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Rule Name</label>
                <input
                    type="text"
                    required
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    value={formData.rule_name || ''}
                    onChange={(e) => setFormData({ ...formData, rule_name: e.target.value })}
                    placeholder="e.g., Warm Humid Conditions"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Description</label>
                <textarea
                    rows={3}
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                    value={formData.description || ''}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    placeholder="Describe when this rule applies..."
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Conditions (JSON)</label>
                <textarea
                    rows={4}
                    required
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent font-mono text-sm"
                    value={formData.conditions ? JSON.stringify(formData.conditions, null, 2) : '{\n  \n}'}
                    onChange={(e) => {
                        try {
                            setFormData({ ...formData, conditions: JSON.parse(e.target.value) });
                        } catch { }
                    }}
                    placeholder='{"temperature_min": 20, "humidity_min": 70}'
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Impact (JSON)</label>
                <textarea
                    rows={4}
                    required
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent font-mono text-sm"
                    value={formData.impact ? JSON.stringify(formData.impact, null, 2) : '{\n  \n}'}
                    onChange={(e) => {
                        try {
                            setFormData({ ...formData, impact: JSON.parse(e.target.value) });
                        } catch { }
                    }}
                    placeholder='{"confidence_boost": 0.1, "confidence_penalty": -0.15}'
                />
            </div>
            <div className="grid grid-cols-2 gap-4">
                <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Priority</label>
                    <input
                        type="number"
                        step="0.1"
                        className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                        value={formData.priority || 1.0}
                        onChange={(e) => setFormData({ ...formData, priority: parseFloat(e.target.value) })}
                    />
                </div>
                <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Active</label>
                    <select
                        className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                        value={formData.is_active !== false ? 'true' : 'false'}
                        onChange={(e) => setFormData({ ...formData, is_active: e.target.value === 'true' })}
                    >
                        <option value="true">Yes</option>
                        <option value="false">No</option>
                    </select>
                </div>
            </div>
        </>
    );
}
