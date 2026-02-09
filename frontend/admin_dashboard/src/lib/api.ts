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
    getLogs: (page: number = 1, level?: string, date?: string) => {
        const params = new URLSearchParams({ page: String(page) });
        if (level) params.append('level', level);
        if (date) params.append('date', date);
        return api.get(`/admin/logs?${params}`);
    },
    getDiagnoses: (page: number = 1, filters?: { disease?: string; crop?: string }) => {
        const params = new URLSearchParams({ page: String(page) });
        if (filters?.disease) params.append('disease', filters.disease);
        if (filters?.crop) params.append('crop_type', filters.crop);
        return api.get(`/admin/diagnoses?${params}`);
    },
};

export const agronomyApi = {
    // Diagnostic Rules
    getDiagnosticRules: (diseaseId?: string) => {
        const params = diseaseId ? `?disease_id=${diseaseId}` : '';
        return api.get(`/agronomy/admin/rules${params}`);
    },
    createDiagnosticRule: (data: {
        disease_id: string;
        rule_name: string;
        description?: string;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        conditions: Record<string, any>;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        impact: Record<string, any>;
        priority?: number;
        is_active?: boolean;
    }) => api.post('/agronomy/admin/rules', data),
    getDiagnosticRule: (id: string) => api.get(`/agronomy/admin/rules/${id}`),
    updateDiagnosticRule: (id: string, data: Partial<{
        rule_name: string;
        description: string;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        conditions: Record<string, any>;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        impact: Record<string, any>;
        priority: number;
        is_active: boolean;
    }>) => api.put(`/agronomy/admin/rules/${id}`, data),
    deleteDiagnosticRule: (id: string) => api.delete(`/agronomy/admin/rules/${id}`),

    // Treatment Constraints
    getTreatmentConstraints: (treatmentType?: string) => {
        const params = treatmentType ? `?treatment_type=${treatmentType}` : '';
        return api.get(`/agronomy/admin/constraints${params}`);
    },
    createTreatmentConstraint: (data: {
        treatment_name: string;
        treatment_type: string;
        constraint_description: string;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        restricted_conditions: Record<string, any>;
        enforcement_level?: string;
        risk_level?: string;
    }) => api.post('/agronomy/admin/constraints', data),
    getTreatmentConstraint: (id: string) => api.get(`/agronomy/admin/constraints/${id}`),
    updateTreatmentConstraint: (id: string, data: Partial<{
        treatment_name: string;
        treatment_type: string;
        constraint_description: string;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        restricted_conditions: Record<string, any>;
        enforcement_level: string;
        risk_level: string;
    }>) => api.put(`/agronomy/admin/constraints/${id}`, data),
    deleteTreatmentConstraint: (id: string) => api.delete(`/agronomy/admin/constraints/${id}`),

    // Seasonal Patterns
    getSeasonalPatterns: (cropId?: string, diseaseId?: string) => {
        const params = new URLSearchParams();
        if (cropId) params.append('crop_id', cropId);
        if (diseaseId) params.append('disease_id', diseaseId);
        const query = params.toString();
        return api.get(`/agronomy/admin/patterns${query ? `?${query}` : ''}`);
    },
    createSeasonalPattern: (data: {
        disease_id: string;
        crop_id: string;
        region?: string;
        season: string;
        likelihood_score?: number;
    }) => api.post('/agronomy/admin/patterns', data),
    getSeasonalPattern: (id: string) => api.get(`/agronomy/admin/patterns/${id}`),
    updateSeasonalPattern: (id: string, data: Partial<{
        region: string;
        season: string;
        likelihood_score: number;
    }>) => api.put(`/agronomy/admin/patterns/${id}`, data),
    deleteSeasonalPattern: (id: string) => api.delete(`/agronomy/admin/patterns/${id}`),
};

export default api;
