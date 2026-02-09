'use client';

import { useEffect, useState } from 'react';
import { AlertCircle } from 'lucide-react';
import { adminApi } from '@/lib/api';
import { User as UserType } from '@/types';
import UserFilters from '@/components/users/UserFilters';
import UsersTable from '@/components/users/UsersTable';

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
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
        } catch (e: any) {
            setError(e.response?.data?.detail || 'Failed to load users');
        } finally {
            setLoading(false);
        }
    };

    // eslint-disable-next-line react-hooks/exhaustive-deps
    useEffect(() => { loadUsers(); }, [roleFilter]);

    const handleSuspend = async (id: string) => {
        if (!confirm('Suspend this user?')) return;
        setActionLoading(id);
        try {
            await adminApi.suspendUser(id);
            await loadUsers();
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
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
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
        } catch (e: any) {
            alert(e.response?.data?.detail || 'Failed to activate user');
        } finally {
            setActionLoading(null);
        }
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
            <UserFilters
                search={search}
                roleFilter={roleFilter}
                onSearchChange={setSearch}
                onRoleChange={setRoleFilter}
                onSearch={loadUsers}
            />

            {/* Users Table */}
            <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
                <UsersTable
                    users={users}
                    loading={loading}
                    actionLoading={actionLoading}
                    onSuspend={handleSuspend}
                    onActivate={handleActivate}
                />
            </div>
        </div>
    );
}
