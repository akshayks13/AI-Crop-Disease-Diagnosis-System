'use client';

import { useEffect, useState } from 'react';
import { Search, UserX, UserCheck, Mail, Shield, User, AlertCircle } from 'lucide-react';
import { adminApi } from '@/lib/api';
import { User as UserType } from '@/types';

export default function UsersPage() {
    const [users, setUsers] = useState<UserType[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [search, setSearch] = useState('');
    const [roleFilter, setRoleFilter] = useState('');
    const [actionLoading, setActionLoading] = useState<string | null>(null);

    const loadUsers = async () => {
        setLoading(true);
        try {
            const res = await adminApi.getUsers(1, roleFilter || undefined, search || undefined);
            setUsers(res.data.users || []);
            setError('');
        } catch (e: any) {
            setError(e.response?.data?.detail || 'Failed to load users');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => { loadUsers(); }, [roleFilter]);

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault();
        loadUsers();
    };

    const handleSuspend = async (id: string) => {
        if (!confirm('Suspend this user?')) return;
        setActionLoading(id);
        try {
            await adminApi.suspendUser(id);
            await loadUsers();
        } catch (e: any) {
            alert(e.response?.data?.detail || 'Failed to suspend user');
        } finally {
            setActionLoading(null);
        }
    };

    const handleActivate = async (id: string) => {
        setActionLoading(id);
        try {
            await adminApi.activateUser(id);
            await loadUsers();
        } catch (e: any) {
            alert(e.response?.data?.detail || 'Failed to activate user');
        } finally {
            setActionLoading(null);
        }
    };

    const roleConfig: Record<string, { bg: string; text: string; icon: any }> = {
        ADMIN: { bg: 'bg-purple-100', text: 'text-purple-700', icon: Shield },
        FARMER: { bg: 'bg-emerald-100', text: 'text-emerald-700', icon: User },
        EXPERT: { bg: 'bg-indigo-100', text: 'text-indigo-700', icon: UserCheck },
    };

    const statusConfig: Record<string, { bg: string; text: string; dot: string }> = {
        ACTIVE: { bg: 'bg-emerald-50', text: 'text-emerald-700', dot: 'bg-emerald-500' },
        PENDING: { bg: 'bg-amber-50', text: 'text-amber-700', dot: 'bg-amber-500' },
        SUSPENDED: { bg: 'bg-red-50', text: 'text-red-700', dot: 'bg-red-500' },
    };

    if (error && !loading) {
        return (
            <div className="bg-red-50 border border-red-200 rounded-xl p-6 text-red-600">
                <div className="flex items-center gap-2">
                    <AlertCircle size={18} />
                    <p className="font-medium">Error loading users</p>
                </div>
                <p className="text-sm mt-1">{error}</p>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            {/* Header */}
            <div>
                <h1 className="text-2xl font-bold text-slate-900">User Management</h1>
                <p className="text-slate-500 text-sm mt-0.5">Manage all users in the system</p>
            </div>

            {/* Search & Filter */}
            <div className="bg-white rounded-xl border border-slate-200 p-4">
                <form onSubmit={handleSearch} className="flex gap-3">
                    <div className="relative flex-1">
                        <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                        <input
                            type="text"
                            placeholder="Search by name or email..."
                            className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:border-indigo-500 focus:bg-white focus:ring-2 focus:ring-indigo-100 outline-none transition-all text-slate-900 placeholder:text-slate-400"
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                        />
                    </div>
                    <select
                        className="px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:border-indigo-500 outline-none transition-all min-w-[140px] text-slate-900"
                        value={roleFilter}
                        onChange={(e) => setRoleFilter(e.target.value)}
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

            {/* Users Table */}
            <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
                {loading ? (
                    <div className="flex items-center justify-center h-64">
                        <div className="w-8 h-8 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin" />
                    </div>
                ) : users.length === 0 ? (
                    <div className="p-16 text-center">
                        <User size={40} className="text-slate-300 mx-auto mb-4" />
                        <p className="text-slate-500">No users found</p>
                    </div>
                ) : (
                    <table className="w-full">
                        <thead>
                            <tr className="bg-slate-50 border-b border-slate-200">
                                <th className="px-5 py-3 text-left text-[10px] font-semibold text-slate-500 uppercase tracking-wider">User</th>
                                <th className="px-5 py-3 text-left text-[10px] font-semibold text-slate-500 uppercase tracking-wider">Role</th>
                                <th className="px-5 py-3 text-left text-[10px] font-semibold text-slate-500 uppercase tracking-wider">Status</th>
                                <th className="px-5 py-3 text-right text-[10px] font-semibold text-slate-500 uppercase tracking-wider">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                            {users.map((user) => {
                                const role = roleConfig[user.role] || roleConfig.FARMER;
                                const status = statusConfig[user.status] || statusConfig.ACTIVE;
                                const RoleIcon = role.icon;

                                return (
                                    <tr key={user.id} className="hover:bg-slate-50 transition-colors">
                                        <td className="px-5 py-4">
                                            <div className="flex items-center gap-3">
                                                <div className={`w-10 h-10 ${role.bg} rounded-lg flex items-center justify-center font-semibold text-sm ${role.text}`}>
                                                    {user.full_name.split(' ').map(n => n[0]).join('')}
                                                </div>
                                                <div>
                                                    <p className="text-sm font-semibold text-slate-900">{user.full_name}</p>
                                                    <p className="text-xs text-slate-500 flex items-center gap-1">
                                                        <Mail size={11} />
                                                        {user.email}
                                                    </p>
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-5 py-4">
                                            <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 ${role.bg} ${role.text} rounded-md text-xs font-medium`}>
                                                <RoleIcon size={12} />
                                                {user.role}
                                            </span>
                                        </td>
                                        <td className="px-5 py-4">
                                            <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 ${status.bg} ${status.text} rounded-md text-xs font-medium`}>
                                                <span className={`w-1.5 h-1.5 ${status.dot} rounded-full`} />
                                                {user.status}
                                            </span>
                                        </td>
                                        <td className="px-5 py-4 text-right">
                                            {user.status === 'SUSPENDED' ? (
                                                <button
                                                    onClick={() => handleActivate(user.id)}
                                                    disabled={actionLoading === user.id}
                                                    className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-emerald-600 text-white rounded-md text-xs font-medium hover:bg-emerald-700 transition-all disabled:opacity-50"
                                                >
                                                    {actionLoading === user.id ? (
                                                        <div className="w-3 h-3 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                                    ) : (
                                                        <UserCheck size={14} />
                                                    )}
                                                    Activate
                                                </button>
                                            ) : user.role !== 'ADMIN' ? (
                                                <button
                                                    onClick={() => handleSuspend(user.id)}
                                                    disabled={actionLoading === user.id}
                                                    className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-white border border-red-200 text-red-600 rounded-md text-xs font-medium hover:bg-red-50 transition-all disabled:opacity-50"
                                                >
                                                    <UserX size={14} /> Suspend
                                                </button>
                                            ) : (
                                                <span className="text-slate-400 text-xs">Protected</span>
                                            )}
                                        </td>
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                )}
            </div>
        </div>
    );
}
