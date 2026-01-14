'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { Leaf, LayoutDashboard, Users, UserCheck, ScrollText, LogOut } from 'lucide-react';

const navItems = [
    { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
    { href: '/dashboard/experts', label: 'Expert Approval', icon: UserCheck },
    { href: '/dashboard/users', label: 'Users', icon: Users },
    { href: '/dashboard/logs', label: 'System Logs', icon: ScrollText },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
    const pathname = usePathname();
    const router = useRouter();

    const handleLogout = () => {
        localStorage.removeItem('access_token');
        router.push('/login');
    };

    return (
        <div className="flex min-h-screen">
            {/* Sidebar */}
            <aside className="w-64 bg-white border-r border-gray-200 p-6 flex flex-col">
                <div className="flex items-center gap-3 pb-6 border-b border-gray-100 mb-6">
                    <Leaf size={28} className="text-green-700" />
                    <h1 className="text-lg font-bold text-green-700">Crop Admin</h1>
                </div>

                <nav className="flex flex-col gap-1 flex-1">
                    {navItems.map((item) => (
                        <Link
                            key={item.href}
                            href={item.href}
                            className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${pathname === item.href
                                    ? 'bg-green-700 text-white'
                                    : 'text-gray-600 hover:bg-gray-100'
                                }`}
                        >
                            <item.icon size={20} />
                            {item.label}
                        </Link>
                    ))}
                </nav>

                <button
                    onClick={handleLogout}
                    className="flex items-center gap-3 px-4 py-3 rounded-xl text-gray-600 hover:bg-red-50 hover:text-red-600 transition-all mt-auto"
                >
                    <LogOut size={20} />
                    Logout
                </button>
            </aside>

            {/* Main Content */}
            <main className="flex-1 p-8 overflow-y-auto bg-gray-50">{children}</main>
        </div>
    );
}
