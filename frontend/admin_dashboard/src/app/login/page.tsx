'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Leaf } from 'lucide-react';
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
                return;
            }

            localStorage.setItem('access_token', access_token);
            router.push('/dashboard');
        } catch (err: any) {
            setError(err.response?.data?.detail || 'Login failed');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-700 to-green-500">
            <div className="bg-white rounded-2xl shadow-2xl p-10 w-full max-w-md">
                <div className="text-center mb-8">
                    <div className="inline-flex bg-green-100 p-4 rounded-2xl mb-4">
                        <Leaf size={40} className="text-green-700" />
                    </div>
                    <h1 className="text-2xl font-bold text-green-700">Admin Dashboard</h1>
                    <p className="text-gray-500 mt-1">Crop Disease Diagnosis System</p>
                </div>

                <form onSubmit={handleSubmit} className="space-y-5">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                        <input
                            type="email"
                            className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent outline-none transition"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                        />
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
                        <input
                            type="password"
                            className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent outline-none transition"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                        />
                    </div>

                    {error && (
                        <div className="text-red-600 text-sm bg-red-50 p-3 rounded-lg">{error}</div>
                    )}

                    <button
                        type="submit"
                        className="w-full bg-green-700 text-white py-3 rounded-lg font-semibold hover:bg-green-800 transition disabled:opacity-50"
                        disabled={loading}
                    >
                        {loading ? 'Signing in...' : 'Sign In'}
                    </button>
                </form>
            </div>
        </div>
    );
}
