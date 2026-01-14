'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function Home() {
  const router = useRouter();

  useEffect(() => {
    const token = localStorage.getItem('access_token');
    router.replace(token ? '/dashboard' : '/login');
  }, [router]);

  return (
    <div className="flex items-center justify-center min-h-screen bg-gradient-to-br from-green-700 to-green-500">
      <div className="text-white text-xl">Loading...</div>
    </div>
  );
}
