import { Search } from 'lucide-react';

interface UserFiltersProps {
    search: string;
    roleFilter: string;
    onSearchChange: (search: string) => void;
    onRoleChange: (role: string) => void;
    onSearch: () => void;
}

export default function UserFilters({ search, roleFilter, onSearchChange, onRoleChange, onSearch }: UserFiltersProps) {
    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        onSearch();
    };

    return (
        <div className="bg-white rounded-xl border border-slate-200 p-4">
            <form onSubmit={handleSubmit} className="flex gap-3">
                <div className="relative flex-1">
                    <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                    <input
                        type="text"
                        placeholder="Search by name or email..."
                        className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:border-indigo-500 focus:bg-white focus:ring-2 focus:ring-indigo-100 outline-none transition-all text-slate-900 placeholder:text-slate-400"
                        value={search}
                        onChange={(e) => onSearchChange(e.target.value)}
                    />
                </div>
                <select
                    className="px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:border-indigo-500 outline-none transition-all min-w-[140px] text-slate-900"
                    value={roleFilter}
                    onChange={(e) => onRoleChange(e.target.value)}
                >
                    <option value="">All Roles</option>
                    <option value="FARMER">Farmers</option>
                    <option value="EXPERT">Experts</option>
                    <option value="ADMIN">Admins</option>
                </select>
                <button
                    type="submit"
                    className="px-5 py-2.5 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition-all"
                >
                    Search
                </button>
            </form>
        </div>
    );
}
