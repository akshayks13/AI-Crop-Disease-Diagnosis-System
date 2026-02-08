import { Mail, Shield, User, UserCheck, UserX } from 'lucide-react';
import { User as UserType } from '@/types';

interface UsersTableProps {
    users: UserType[];
    loading: boolean;
    actionLoading: string | null;
    onSuspend: (id: string) => void;
    onActivate: (id: string) => void;
}

export default function UsersTable({ users, loading, actionLoading, onSuspend, onActivate }: UsersTableProps) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
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

    if (loading) {
        return (
            <div className="flex items-center justify-center h-64">
                <div className="w-8 h-8 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin" />
            </div>
        );
    }

    if (users.length === 0) {
        return (
            <div className="p-16 text-center">
                <User size={40} className="text-slate-300 mx-auto mb-4" />
                <p className="text-slate-500">No users found</p>
            </div>
        );
    }

    return (
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
                                        onClick={() => onActivate(user.id)}
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
                                        onClick={() => onSuspend(user.id)}
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
    );
}
