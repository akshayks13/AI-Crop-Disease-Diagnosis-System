import { test, expect } from '@playwright/test';

test.describe('Agronomy and Questions', () => {
    test.describe.configure({ retries: 2 });

    test.beforeEach(async ({ page }) => {
        // Authenticate with real API
        await page.goto('/login');
        await page.getByPlaceholder('admin@example.com').fill('admin@cropdiagnosis.com');
        await page.getByPlaceholder('••••••••').fill('admin123');
        await page.getByRole('button', { name: 'Sign In' }).click();
        await expect(page).toHaveURL(/.*\/dashboard/, { timeout: 15000 });
    });

    test('should load Agronomy Intelligence page', async ({ page }) => {
        await page.goto('/dashboard/agronomy');

        await expect(page.getByRole('heading', { name: 'Agronomy Intelligence' })).toBeVisible();
        await expect(page.getByRole('button', { name: /Diagnostic Rules/i })).toBeVisible();
        await expect(page.getByRole('button', { name: /Treatment Constraints/i })).toBeVisible();
        await expect(page.getByRole('button', { name: /Seasonal Patterns/i })).toBeVisible();
    });

    test('should load Questions list', async ({ page }) => {
        await page.goto('/dashboard/questions');

        await expect(page.getByRole('heading', { name: 'Questions' })).toBeVisible();
        await expect(page.getByRole('button', { name: 'Refresh' })).toBeVisible();
    });
});
