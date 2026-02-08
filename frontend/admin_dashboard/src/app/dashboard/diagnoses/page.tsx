'use client';

import { useEffect, useState } from 'react';
import { AlertCircle } from 'lucide-react';
import { adminApi } from '@/lib/api';
import DiagnosesTable from '@/components/diagnoses/DiagnosesTable';
import DiagnosisFilters from '@/components/diagnoses/DiagnosisFilters';
import ImageZoomModal from '@/components/diagnoses/ImageZoomModal';

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

export default function DiagnosesPage() {
    const [diagnoses, setDiagnoses] = useState<Diagnosis[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [filters, setFilters] = useState({ disease: '', crop: '' });
    const [page, setPage] = useState(1);
    const [selectedImage, setSelectedImage] = useState<string | null>(null);

    const loadDiagnoses = async () => {
        setLoading(true);
        try {
            const res = await adminApi.getDiagnoses(page, filters);
            setDiagnoses(res.data.diagnoses || []);
            setError('');
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
        } catch (e: any) {
            setError(e.response?.data?.detail || 'Failed to load diagnoses');
        } finally {
            setLoading(false);
        }
    };

    // eslint-disable-next-line react-hooks/exhaustive-deps
    useEffect(() => { loadDiagnoses(); }, [page]);

    const handleSearch = () => {
        setPage(1); // Reset to page 1 on filter change
        loadDiagnoses();
    };

    return (
        <div className="space-y-6">
            {/* Header */}
            <div>
                <h1 className="text-2xl font-bold text-slate-900">Diagnoses & Reports</h1>
                <p className="text-slate-500 text-sm mt-0.5">Monitor AI diagnosis activity</p>
            </div>

            {/* Filter Bar */}
            <DiagnosisFilters
                filters={filters}
                onFiltersChange={setFilters}
                onSearch={handleSearch}
                onRefresh={loadDiagnoses}
            />

            {/* Content Area */}
            {error && (
                <div className="bg-red-50 border border-red-200 rounded-xl p-4 text-red-600 flex items-center gap-3">
                    <AlertCircle size={20} />
                    <p>{error}</p>
                </div>
            )}

            <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
                <DiagnosesTable
                    diagnoses={diagnoses}
                    loading={loading}
                    onImageClick={setSelectedImage}
                />
            </div>

            {/* Image Zoom Modal */}
            <ImageZoomModal
                imagePath={selectedImage}
                onClose={() => setSelectedImage(null)}
            />
        </div>
    );
}
