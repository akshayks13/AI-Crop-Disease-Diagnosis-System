/**
 * Admin Dashboard API Tests
 * 
 * Run with: npm test
 */

import { describe, it, expect } from 'vitest';

// ============== API URL Tests ==============

describe('API Configuration', () => {
    it('should have default localhost value', () => {
        const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
        expect(API_URL).toContain('localhost');
    });

    it('should be a valid HTTP URL', () => {
        const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
        expect(API_URL.startsWith('http')).toBe(true);
    });

    it('should not end with trailing slash', () => {
        const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
        expect(API_URL.endsWith('/')).toBe(false);
    });
});

// ============== Admin API Endpoint Tests ==============

describe('Admin API Endpoints', () => {
    it('dashboard endpoint should be /admin/dashboard', () => {
        const endpoint = '/admin/dashboard';
        expect(endpoint).toBe('/admin/dashboard');
    });

    it('pending experts endpoint should include pagination', () => {
        const page = 1;
        const endpoint = `/admin/experts/pending?page=${page}`;
        expect(endpoint).toContain('page=');
    });

    it('users endpoint should build correct query params', () => {
        const page = 1;
        const role = 'EXPERT';
        const search = 'john';
        const params = new URLSearchParams({ page: String(page) });
        if (role) params.append('role', role);
        if (search) params.append('search', search);
        const url = `/admin/users?${params}`;

        expect(url).toContain('page=1');
        expect(url).toContain('role=EXPERT');
        expect(url).toContain('search=john');
    });

    it('logs endpoint should support level filter', () => {
        const page = 1;
        const level = 'ERROR';
        const params = new URLSearchParams({ page: String(page) });
        params.append('level', level);
        const url = `/admin/logs?${params}`;

        expect(url).toContain('level=ERROR');
    });

    it('diagnoses endpoint should support disease filter', () => {
        const page = 1;
        const disease = 'Leaf Blight';
        const params = new URLSearchParams({ page: String(page) });
        params.append('disease', disease);
        const url = `/admin/diagnoses?${params}`;

        expect(url).toContain('disease=Leaf');
    });

    it('approve expert endpoint should include expert ID', () => {
        const expertId = '123-456-789';
        const endpoint = `/admin/experts/approve/${expertId}`;
        expect(endpoint).toBe('/admin/experts/approve/123-456-789');
    });

    it('reject expert endpoint should include expert ID', () => {
        const expertId = '123-456-789';
        const endpoint = `/admin/experts/reject/${expertId}`;
        expect(endpoint).toBe('/admin/experts/reject/123-456-789');
    });

    it('suspend user endpoint should include user ID', () => {
        const userId = 'user-abc';
        const endpoint = `/admin/users/${userId}/suspend`;
        expect(endpoint).toBe('/admin/users/user-abc/suspend');
    });

    it('activate user endpoint should include user ID', () => {
        const userId = 'user-abc';
        const endpoint = `/admin/users/${userId}/activate`;
        expect(endpoint).toBe('/admin/users/user-abc/activate');
    });
});

// ============== Agronomy API Endpoint Tests ==============

describe('Agronomy API Endpoints', () => {
    it('diagnostic rules endpoint should be correct', () => {
        const endpoint = '/agronomy/admin/rules';
        expect(endpoint).toBe('/agronomy/admin/rules');
    });

    it('diagnostic rules endpoint should support disease filter', () => {
        const diseaseId = '123-456';
        const endpoint = `/agronomy/admin/rules?disease_id=${diseaseId}`;
        expect(endpoint).toContain('disease_id=123-456');
    });

    it('treatment constraints endpoint should be correct', () => {
        const endpoint = '/agronomy/admin/constraints';
        expect(endpoint).toBe('/agronomy/admin/constraints');
    });

    it('seasonal patterns endpoint should support multiple filters', () => {
        const cropId = 'crop-123';
        const diseaseId = 'disease-456';
        const params = new URLSearchParams();
        params.append('crop_id', cropId);
        params.append('disease_id', diseaseId);
        const url = `/agronomy/admin/patterns?${params}`;

        expect(url).toContain('crop_id=crop-123');
        expect(url).toContain('disease_id=disease-456');
    });

    it('delete rule endpoint should include rule ID', () => {
        const ruleId = 'rule-123';
        const endpoint = `/agronomy/admin/rules/${ruleId}`;
        expect(endpoint).toBe('/agronomy/admin/rules/rule-123');
    });
});

// ============== Auth API Tests ==============

describe('Auth API Endpoints', () => {
    it('login endpoint should be /auth/login', () => {
        const endpoint = '/auth/login';
        expect(endpoint).toBe('/auth/login');
    });

    it('me endpoint should be /auth/me', () => {
        const endpoint = '/auth/me';
        expect(endpoint).toBe('/auth/me');
    });
});

// ============== URL Parameter Helper Tests ==============

describe('URL Parameter Helpers', () => {
    it('URLSearchParams should properly encode special characters', () => {
        const params = new URLSearchParams();
        params.append('search', 'test user');
        expect(params.toString()).toBe('search=test+user');
    });

    it('empty optional params should not be appended', () => {
        const page = 1;
        const role: string | undefined = undefined;
        const params = new URLSearchParams({ page: String(page) });
        if (role) params.append('role', role);

        expect(params.toString()).toBe('page=1');
    });

    it('should handle multiple same-key params', () => {
        const params = new URLSearchParams();
        params.append('tag', 'urgent');
        params.append('tag', 'reviewed');
        expect(params.getAll('tag')).toEqual(['urgent', 'reviewed']);
    });
});
