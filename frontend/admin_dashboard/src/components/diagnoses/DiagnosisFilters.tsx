import { Search, Sprout, Filter } from 'lucide-react';

interface DiagnosisFiltersProps {
    filters: { disease: string; crop: string };
    onFiltersChange: (filters: { disease: string; crop: string }) => void;
    onSearch: () => void;
    onRefresh: () => void;
}

export default function DiagnosisFilters({ filters, onFiltersChange, onSearch, onRefresh }: DiagnosisFiltersProps) {
    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        onSearch();
    };

    return (
        <div className="bg-white rounded-xl border border-slate-200 p-4">
            <form onSubmit={handleSubmit} className="flex gap-3 flex-wrap md:flex-nowrap">
                <div className="relative flex-1 min-w-[200px]">
                    <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                    <input
                        type="text"
                        placeholder="Filter by Disease..."
                        className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:border-indigo-500 focus:bg-white focus:ring-2 focus:ring-indigo-100 outline-none transition-all text-slate-900 placeholder:text-slate-400"
                        value={filters.disease}
                        onChange={(e) => onFiltersChange({ ...filters, disease: e.target.value })}
                    />
                </div>
                <div className="relative flex-1 min-w-[200px]">
                    <Sprout className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                    <input
                        type="text"
                        placeholder="Filter by Crop..."
                        className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:border-indigo-500 focus:bg-white focus:ring-2 focus:ring-indigo-100 outline-none transition-all text-slate-900 placeholder:text-slate-400"
                        value={filters.crop}
                        onChange={(e) => onFiltersChange({ ...filters, crop: e.target.value })}
                    />
                </div>
                <button
                    type="submit"
                    className="px-5 py-2.5 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition-all flex items-center gap-2"
                >
                    <Filter size={16} />
                    Apply
                </button>
                <button
                    type="button"
                    onClick={onRefresh}
                    className="px-4 py-2.5 bg-slate-100 text-slate-600 rounded-lg text-sm font-medium hover:bg-slate-200 transition-all"
                >
                    Refresh
                </button>
            </form>
        </div>
    );
}
