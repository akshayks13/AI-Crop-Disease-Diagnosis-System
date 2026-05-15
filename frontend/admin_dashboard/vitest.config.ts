import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        // Only include unit test files — explicitly exclude Playwright E2E folder
        include: ['src/**/*.{test,spec}.{ts,tsx}', '__tests__/**/*.{test,spec}.{ts,tsx}'],
        exclude: [
            'tests/e2e/**',
            'tests/**/*.spec.ts',
            'node_modules/**',
            '.next/**',
        ],
        environment: 'node',
    },
});
