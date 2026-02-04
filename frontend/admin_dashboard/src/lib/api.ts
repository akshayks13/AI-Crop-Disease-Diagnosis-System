import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

const api = axios.create({
    baseURL: API_URL,
    headers: { 'Content-Type': 'application/json' },
});

api.interceptors.request.use((config) => {
    if (typeof window !== 'undefined') {
        const token = localStorage.getItem('access_token');
        if (token) config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});

api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response?.status === 401 && typeof window !== 'undefined') {
            localStorage.removeItem('access_token');
            window.location.href = '/login';
        }
        return Promise.reject(error);
    }
);

export const authApi = {
    login: (email: string, password: string) => api.post('/auth/login', { email, password }),
    getMe: () => api.get('/auth/me'),
};

export const adminApi = {
    getDashboard: () => api.get('/admin/dashboard'),
    getDailyMetrics: (days: number = 7) => api.get(`/admin/metrics/daily?days=${days}`),
    getPendingExperts: (page: number = 1) => api.get(`/admin/experts/pending?page=${page}`),
    approveExpert: (id: string) => api.post(`/admin/experts/approve/${id}`),
    rejectExpert: (id: string, reason?: string) => api.post(`/admin/experts/reject/${id}`, { reason }),
    getUsers: (page: number = 1, role?: string, search?: string) => {
        const params = new URLSearchParams({ page: String(page) });
        if (role) params.append('role', role);
        if (search) params.append('search', search);
        return api.get(`/admin/users?${params}`);
    },
    suspendUser: (id: string) => api.post(`/admin/users/${id}/suspend`),
    activateUser: (id: string) => api.post(`/admin/users/${id}/activate`),
    getLogs: (page: number = 1, level?: string) => {
        const params = new URLSearchParams({ page: String(page) });
        if (level) params.append('level', level);
        return api.get(`/admin/logs?${params}`);
    },
    getDiagnoses: (page: number = 1, filters?: { disease?: string; crop?: string }) => {
        const params = new URLSearchParams({ page: String(page) });
        if (filters?.disease) params.append('disease', filters.disease);
        if (filters?.crop) params.append('crop_type', filters.crop);
        return api.get(`/admin/diagnoses?${params}`);
    },
};

export default api;
