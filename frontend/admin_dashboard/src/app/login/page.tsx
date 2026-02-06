'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Mail, Lock, ArrowRight, Shield } from 'lucide-react';
import { authApi } from '@/lib/api';

export default function LoginPage() {
    const router = useRouter();
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');

        try {
            const response = await authApi.login(email, password);
            const { access_token, user } = response.data;

            if (user.role !== 'ADMIN') {
                setError('Access denied. Admin role required.');
                setLoading(false);
                return;
            }

            localStorage.setItem('access_token', access_token);
            router.push('/dashboard');
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
        } catch (err: any) {
            console.error('Login error:', err);
            setError(err.response?.data?.detail || 'Login failed. Please check your credentials.');
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen flex">
            {/* Left Panel - Branding */}
            <div className="hidden lg:flex lg:w-1/2 relative overflow-hidden">
                <div className="absolute inset-0 bg-gradient-to-br from-indigo-600 via-indigo-700 to-slate-900" />
                <div className="absolute inset-0">
                    <div className="absolute top-20 left-20 w-72 h-72 bg-indigo-400/20 rounded-full blur-3xl" />
                    <div className="absolute bottom-20 right-20 w-96 h-96 bg-purple-500/20 rounded-full blur-3xl" />
                    <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-64 h-64 bg-white/5 rounded-full blur-2xl" />
                </div>
                <div className="relative z-10 flex flex-col justify-center px-16 text-white">
                    <div className="flex items-center gap-4 mb-10">
                        <div className="p-4 bg-white/10 backdrop-blur-sm rounded-2xl border border-white/20">
                            <Shield size={36} className="text-indigo-200" />
                        </div>
                        <div>
                            <h1 className="text-2xl font-bold">Crop Diagnosis</h1>
                            <p className="text-indigo-200 text-sm">Administration Portal</p>
                        </div>
                    </div>
                    <h2 className="text-5xl font-bold mb-6 leading-tight tracking-tight">
                        Manage Your<br />Platform
                    </h2>
                    <p className="text-lg text-indigo-100/80 max-w-md leading-relaxed">
                        Monitor system health, approve experts, and keep your agricultural AI platform running smoothly.
                    </p>
                    <div className="mt-12 space-y-4">
                        {['Real-time analytics & insights', 'Expert verification system', 'Complete user management'].map((item, i) => (
                            <div key={i} className="flex items-center gap-3 text-indigo-100/90">
                                <div className="w-1.5 h-1.5 bg-indigo-300 rounded-full" />
                                <span className="text-sm font-medium">{item}</span>
                            </div>
                        ))}
                    </div>
                </div>
            </div>

            {/* Right Panel - Login Form */}
            <div className="flex-1 flex items-center justify-center p-8 bg-slate-50">
                <div className="w-full max-w-md">
                    {/* Mobile Logo */}
                    <div className="lg:hidden flex items-center gap-3 mb-10 justify-center">
                        <div className="p-3 bg-indigo-600 text-white rounded-xl">
                            <Shield size={24} />
                        </div>
                        <h1 className="text-xl font-bold text-slate-900">Crop Admin</h1>
                    </div>

                    <div className="bg-white rounded-2xl shadow-xl shadow-slate-200/50 p-10 border border-slate-100">
                        <div className="mb-8">
                            <h2 className="text-2xl font-bold text-slate-900 mb-2">Welcome back</h2>
                            <p className="text-slate-500">Sign in to access the admin panel</p>
                        </div>

                        <form onSubmit={handleSubmit} className="space-y-5">
                            <div>
                                <label className="block text-sm font-semibold text-slate-700 mb-2">
                                    Email Address
                                </label>
                                <div className="relative">
                                    <Mail className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                                    <input
                                        type="email"
                                        className="w-full pl-11 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-xl focus:border-indigo-500 focus:bg-white focus:ring-4 focus:ring-indigo-100 outline-none transition-all text-sm text-slate-900 placeholder:text-slate-400"
                                        placeholder="admin@example.com"
                                        value={email}
                                        onChange={(e) => setEmail(e.target.value)}
                                        required
                                    />
                                </div>
                            </div>

                            <div>
                                <label className="block text-sm font-semibold text-slate-700 mb-2">
                                    Password
                                </label>
                                <div className="relative">
                                    <Lock className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                                    <input
                                        type="password"
                                        className="w-full pl-11 pr-4 py-3.5 bg-slate-50 border border-slate-200 rounded-xl focus:border-indigo-500 focus:bg-white focus:ring-4 focus:ring-indigo-100 outline-none transition-all text-sm text-slate-900 placeholder:text-slate-400"
                                        placeholder="••••••••"
                                        value={password}
                                        onChange={(e) => setPassword(e.target.value)}
                                        required
                                    />
                                </div>
                            </div>

                            {error && (
                                <div className="flex items-center gap-3 p-4 bg-red-50 border border-red-100 rounded-xl text-red-600 text-sm">
                                    <div className="w-2 h-2 bg-red-500 rounded-full flex-shrink-0" />
                                    {error}
                                </div>
                            )}

                            <button
                                type="submit"
                                disabled={loading}
                                className="w-full flex items-center justify-center gap-2.5 py-3.5 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 focus:ring-4 focus:ring-indigo-200 transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-lg shadow-indigo-200 text-sm"
                            >
                                {loading ? (
                                    <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                ) : (
                                    <>
                                        Sign In
                                        <ArrowRight size={18} />
                                    </>
                                )}
                            </button>
                        </form>

                        <div className="mt-8 pt-6 border-t border-slate-100 text-center">
                            <p className="text-sm text-slate-500">
                                Default: <code className="px-2 py-1 bg-slate-100 rounded text-slate-700 text-xs">admin@cropdiagnosis.com</code>
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
