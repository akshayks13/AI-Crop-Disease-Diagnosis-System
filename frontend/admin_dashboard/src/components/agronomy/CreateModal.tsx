'use client';

import { useState } from 'react';
import { X } from 'lucide-react';
import DiagnosticRuleForm from './forms/DiagnosticRuleForm';
import TreatmentConstraintForm from './forms/TreatmentConstraintForm';
import SeasonalPatternForm from './forms/SeasonalPatternForm';

type Tab = 'rules' | 'constraints' | 'patterns';

interface CreateModalProps {
    type: Tab;
    onClose: () => void;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    onCreate: (data: any) => void;
}

export default function CreateModal({ type, onClose, onCreate }: CreateModalProps) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const [formData, setFormData] = useState<any>({});
    const [submitting, setSubmitting] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitting(true);
        await onCreate(formData);
        setSubmitting(false);
    };

    return (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
                {/* Header */}
                <div className="sticky top-0 bg-white border-b border-slate-200 px-6 py-4 flex justify-between items-center">
                    <h2 className="text-xl font-bold text-slate-900">
                        {type === 'rules' && 'Add Diagnostic Rule'}
                        {type === 'constraints' && 'Add Treatment Constraint'}
                        {type === 'patterns' && 'Add Seasonal Pattern'}
                    </h2>
                    <button onClick={onClose} className="text-slate-400 hover:text-slate-600">
                        <X size={20} />
                    </button>
                </div>

                {/* Form */}
                <form onSubmit={handleSubmit} className="p-6 space-y-4">
                    {type === 'rules' && <DiagnosticRuleForm formData={formData} setFormData={setFormData} />}
                    {type === 'constraints' && <TreatmentConstraintForm formData={formData} setFormData={setFormData} />}
                    {type === 'patterns' && <SeasonalPatternForm formData={formData} setFormData={setFormData} />}

                    {/* Actions */}
                    <div className="flex gap-3 pt-4 border-t border-slate-200">
                        <button
                            type="button"
                            onClick={onClose}
                            className="flex-1 px-4 py-2 border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            disabled={submitting}
                            className="flex-1 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
                        >
                            {submitting ? 'Creating...' : 'Create'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
