import { test, expect } from '@playwright/test';

test.describe('System Logs', () => {
    test.describe.configure({ retries: 2 });

    test.beforeEach(async ({ page }) => {
        // Authenticate with real API
        await page.goto('/login');
        await page.getByPlaceholder('admin@example.com').fill('admin@cropdiagnosis.com');
        await page.getByPlaceholder('••••••••').fill('admin123');
        await page.getByRole('button', { name: 'Sign In' }).click();
        await expect(page).toHaveURL(/.*\/dashboard/, { timeout: 15000 });

        // Use domcontentloaded to avoid Firefox NS_BINDING_ABORTED on sub-page nav
        try {
            await page.goto('/dashboard/logs', { waitUntil: 'domcontentloaded', timeout: 10000 });
        } catch {
            await page.waitForURL(/.*\/dashboard/, { timeout: 5000 }).catch(() => { });
        }
    });

    test('should display log statistics', async ({ page }) => {
        await expect(page.getByRole('heading', { name: 'System Logs' })).toBeVisible();
        await expect(page.getByText('Total Users')).toBeVisible();
        await expect(page.getByText('New Signups')).toBeVisible();
        await expect(page.getByText('Critical Errors')).toBeVisible();
    });

    test('should filter logs by level', async ({ page }) => {
        // Wait for the select dropdown to appear (page must finish loading)
        const levelSelect = page.locator('select');
        await expect(levelSelect).toBeVisible({ timeout: 10000 });

        await levelSelect.selectOption('ERROR');
        await page.waitForTimeout(500); // wait for state update
        await expect(levelSelect).toHaveValue('ERROR');
    });
});
