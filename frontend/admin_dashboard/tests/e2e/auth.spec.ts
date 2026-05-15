import { test, expect } from '@playwright/test';

test.describe('Authentication Flow', () => {
    const adminEmail = 'admin@cropdiagnosis.com';
    const adminPassword = 'admin123';

    test.beforeEach(async ({ page }) => {
        await page.goto('/login');
    });

    test('should display login page correctly', async ({ page }) => {
        await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible();
        await expect(page.getByPlaceholder('admin@example.com')).toBeVisible();
        await expect(page.getByPlaceholder('••••••••')).toBeVisible();
        await expect(page.getByRole('button', { name: 'Sign In' })).toBeVisible();
    });


    test('should successfully login and redirect to dashboard', async ({ page }) => {
        await page.getByPlaceholder('admin@example.com').fill(adminEmail);
        await page.getByPlaceholder('••••••••').fill(adminPassword);

        await page.getByRole('button', { name: 'Sign In' }).click();

        // Should redirect to dashboard
        await expect(page).toHaveURL(/.*\/dashboard/, { timeout: 10000 });

        // Check if token was saved
        const token = await page.evaluate(() => localStorage.getItem('access_token'));
        expect(token).toBeTruthy();
    });
});
