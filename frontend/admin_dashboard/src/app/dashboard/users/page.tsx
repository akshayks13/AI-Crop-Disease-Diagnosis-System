'use client';

import { useEffect, useState } from 'react';
import { Search, UserX, UserCheck } from 'lucide-react';
import { adminApi } from '@/lib/api';
import { User } from '@/types';

export default function UsersPage() {
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState('');
    const [roleFilter, setRoleFilter] = useState('');

    const loadUsers = async () => {
        setLoading(true);
        try {
            const res = await adminApi.getUsers(1, roleFilter || undefined, search || undefined);
            setUsers(res.data.users);
        } catch (e) {
            console.error(e);
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
        try {
            await adminApi.suspendUser(id);
            loadUsers();
        } catch (e) {
            alert('Failed');
        }
    };

    const handleActivate = async (id: string) => {
        try {
            await adminApi.activateUser(id);
            loadUsers();
        } catch (e) {
            alert('Failed');
        }
    };

    const statusColors: Record<string, string> = {
        ACTIVE: 'bg-green-100 text-green-700',
        PENDING: 'bg-orange-100 text-orange-700',
        SUSPENDED: 'bg-red-100 text-red-700',
    };

    return (
        <div>
            <h1 className="text-2xl font-bold text-gray-900 mb-8">User Management</h1>

            <div className="bg-white rounded-2xl shadow-md p-4 mb-6">
                <form onSubmit={handleSearch} className="flex gap-3">
                    <input
                        type="text"
                        placeholder="Search by name or email..."
                        className="flex-1 px-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent outline-none"
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                    />
                    <select
                        className="px-4 py-3 border border-gray-200 rounded-lg focus:ring-2 focus:ring-green-500 outline-none"
                        value={roleFilter}
                        onChange={(e) => setRoleFilter(e.target.value)}
                    >
                        <option value="">All Roles</option>
                        <option value="FARMER">Farmers</option>
                        <option value="EXPERT">Experts</option>
                        <option value="ADMIN">Admins</option>
                    </select>
                    <button type="submit" className="px-5 py-3 bg-green-700 text-white rounded-lg hover:bg-green-800 transition">
                        <Search size={18} />
                    </button>
                </form>
            </div>

            <div className="bg-white rounded-2xl shadow-md overflow-hidden">
                {loading ? (
                    <div className="p-8 text-center">Loading...</div>
                ) : (
                    <table className="w-full">
                        <thead className="bg-gray-50">
                            <tr>
                                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase">Name</th>
                                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase">Email</th>
                                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase">Role</th>
                                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase">Status</th>
                                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {users.map((user) => (
                                <tr key={user.id} className="hover:bg-gray-50">
                                    <td className="px-6 py-4 font-medium">{user.full_name}</td>
                                    <td className="px-6 py-4 text-gray-600">{user.email}</td>
                                    <td className="px-6 py-4">
                                        <span className="px-3 py-1 bg-green-100 text-green-700 rounded-full text-xs font-semibold">
                                            {user.role}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`px-3 py-1 rounded-full text-xs font-semibold ${statusColors[user.status]}`}>
                                            {user.status}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4">
                                        {user.status === 'SUSPENDED' ? (
                                            <button
                                                onClick={() => handleActivate(user.id)}
                                                className="flex items-center gap-1 px-3 py-2 bg-green-600 text-white rounded-lg text-sm font-medium hover:bg-green-700 transition"
                                            >
                                                <UserCheck size={14} /> Activate
                                            </button>
                                        ) : user.role !== 'ADMIN' ? (
                                            <button
                                                onClick={() => handleSuspend(user.id)}
                                                className="flex items-center gap-1 px-3 py-2 bg-red-600 text-white rounded-lg text-sm font-medium hover:bg-red-700 transition"
                                            >
                                                <UserX size={14} /> Suspend
                                            </button>
                                        ) : null}
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>
        </div>
    );
}
