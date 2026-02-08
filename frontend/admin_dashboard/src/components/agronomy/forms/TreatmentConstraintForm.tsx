'use client';

interface FormProps {
    formData: any;
    setFormData: (data: any) => void;
}

export default function TreatmentConstraintForm({ formData, setFormData }: FormProps) {
    return (
        <>
            <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Treatment Name</label>
                <input
                    type="text"
                    required
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
                    value={formData.treatment_name || ''}
                    onChange={(e) => setFormData({ ...formData, treatment_name: e.target.value })}
                    placeholder="e.g., Mancozeb 75% WP"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Treatment Type</label>
                <select
                    required
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
                    value={formData.treatment_type || ''}
                    onChange={(e) => setFormData({ ...formData, treatment_type: e.target.value })}
                >
                    <option value="">Select...</option>
                    <option value="chemical">Chemical</option>
                    <option value="organic">Organic</option>
                </select>
            </div>
            <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Constraint Description</label>
                <textarea
                    rows={3}
                    required
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
                    value={formData.constraint_description || ''}
                    onChange={(e) => setFormData({ ...formData, constraint_description: e.target.value })}
                    placeholder="Explain the safety constraint..."
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Restricted Conditions (JSON)</label>
                <textarea
                    rows={4}
                    required
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent font-mono text-sm"
                    value={formData.restricted_conditions ? JSON.stringify(formData.restricted_conditions, null, 2) : '{\n  \n}'}
                    onChange={(e) => {
                        try {
                            setFormData({ ...formData, restricted_conditions: JSON.parse(e.target.value) });
                        } catch { }
                    }}
                    placeholder='{"weather": "rainy", "temperature_max": 35}'
                />
            </div>
            <div className="grid grid-cols-2 gap-4">
                <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Enforcement Level</label>
                    <select
                        className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
                        value={formData.enforcement_level || 'warn'}
                        onChange={(e) => setFormData({ ...formData, enforcement_level: e.target.value })}
                    >
                        <option value="block">Block</option>
                        <option value="warn">Warn</option>
                    </select>
                </div>
                <div>
                    <label className="block text-sm font-medium text-slate-700 mb-1">Risk Level</label>
                    <select
                        className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-transparent"
                        value={formData.risk_level || 'medium'}
                        onChange={(e) => setFormData({ ...formData, risk_level: e.target.value })}
                    >
                        <option value="low">Low</option>
                        <option value="medium">Medium</option>
                        <option value="high">High</option>
                    </select>
                </div>
            </div>
        </>
    );
}
