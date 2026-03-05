import { test, expect } from '@playwright/test';

test.describe('System Logs', () => {
    test.beforeEach(async ({ page }) => {
        // Authenticate with real API
        await page.goto('/login');
        await page.getByPlaceholder('admin@example.com').fill('admin@cropdiagnosis.com');
        await page.getByPlaceholder('••••••••').fill('admin123');
        await page.getByRole('button', { name: 'Sign In' }).click();
        await expect(page).toHaveURL(/.*\/dashboard/, { timeout: 10000 });

        await page.goto('/dashboard/logs');
    });

    test('should display log statistics', async ({ page }) => {
        await expect(page.getByRole('heading', { name: 'System Logs' })).toBeVisible();
        await expect(page.getByText('Total Users')).toBeVisible();
        await expect(page.getByText('New Signups')).toBeVisible();
        await expect(page.getByText('Critical Errors')).toBeVisible();
    });

    test('should filter logs by level', async ({ page }) => {
        await page.getByRole('combobox').selectOption('ERROR');
        await page.waitForTimeout(1000); // wait for fetch
        await expect(page.getByRole('combobox')).toHaveValue('ERROR');
    });
});
