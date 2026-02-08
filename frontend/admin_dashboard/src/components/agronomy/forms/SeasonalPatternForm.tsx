'use client';

interface FormProps {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    formData: any;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    setFormData: (data: any) => void;
}

export default function SeasonalPatternForm({ formData, setFormData }: FormProps) {
    return (
        <>
            <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Disease ID</label>
                <input
                    type="text"
                    required
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    value={formData.disease_id || ''}
                    onChange={(e) => setFormData({ ...formData, disease_id: e.target.value })}
                    placeholder="UUID of the disease"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Crop ID</label>
                <input
                    type="text"
                    required
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    value={formData.crop_id || ''}
                    onChange={(e) => setFormData({ ...formData, crop_id: e.target.value })}
                    placeholder="UUID of the crop"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Season</label>
                <select
                    required
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    value={formData.season || ''}
                    onChange={(e) => setFormData({ ...formData, season: e.target.value })}
                >
                    <option value="">Select...</option>
                    <option value="Kharif">Kharif</option>
                    <option value="Rabi">Rabi</option>
                    <option value="Zaid">Zaid</option>
                    <option value="Summer">Summer</option>
                    <option value="Winter">Winter</option>
                </select>
            </div>
            <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Region (Optional)</label>
                <input
                    type="text"
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    value={formData.region || ''}
                    onChange={(e) => setFormData({ ...formData, region: e.target.value })}
                    placeholder="e.g., Karnataka (leave empty for general)"
                />
            </div>
            <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Likelihood Score (0-1)</label>
                <input
                    type="number"
                    step="0.01"
                    min="0"
                    max="1"
                    className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    value={formData.likelihood_score || 0.5}
                    onChange={(e) => setFormData({ ...formData, likelihood_score: parseFloat(e.target.value) })}
                />
                <p className="text-xs text-slate-500 mt-1">
                    Current: {((formData.likelihood_score || 0.5) * 100).toFixed(0)}%
                </p>
            </div>
        </>
    );
}
