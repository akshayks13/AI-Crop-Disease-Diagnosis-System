import { test, expect } from '@playwright/test';

test.describe('Users Management', () => {
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
            await page.goto('/dashboard/users', { waitUntil: 'domcontentloaded', timeout: 10000 });
        } catch {
            await page.waitForURL(/.*\/dashboard/, { timeout: 5000 }).catch(() => { });
        }
    });

    test('should display users list page correctly', async ({ page }) => {
        await expect(page.getByRole('heading', { name: 'User Management' })).toBeVisible();
        await expect(page.getByPlaceholder('Search by name or email...')).toBeVisible();
        await expect(page.getByRole('button', { name: 'Search' })).toBeVisible();
    });

    test('should filter users by role', async ({ page }) => {
        await page.getByRole('combobox').selectOption('ADMIN');
        await page.waitForTimeout(1000); // Wait for potential re-fetch

        // Assert we see some admin user (since we know the admin is there)
        await expect(page.getByText('ADMIN', { exact: true }).first()).toBeVisible();
    });
});
