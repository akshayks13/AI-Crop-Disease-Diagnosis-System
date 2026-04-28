import { test, expect } from '@playwright/test';

test.describe('Logout Flow', () => {
    test.beforeEach(async ({ page }) => {
        // Login first
        await page.goto('/login');
        await page.getByPlaceholder('admin@example.com').fill('admin@cropdiagnosis.com');
        await page.getByPlaceholder('••••••••').fill('admin123');
        await page.getByRole('button', { name: 'Sign In' }).click();
        await expect(page).toHaveURL(/.*\/dashboard/, { timeout: 10000 });
    });

    test('should log out and redirect to login page', async ({ page }) => {
        // Click logout button in the sidebar
        await page.getByRole('button', { name: /Logout/ }).click();

        // Should be redirected to login page
        await expect(page).toHaveURL(/.*\/login/, { timeout: 8000 });
        await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible();
    });

    test('should clear access_token from localStorage on logout', async ({ page }) => {
        // Verify token exists before logout
        const tokenBefore = await page.evaluate(() => localStorage.getItem('access_token'));
        expect(tokenBefore).toBeTruthy();

        // Logout
        await page.getByRole('button', { name: /Logout/ }).click();
        await expect(page).toHaveURL(/.*\/login/, { timeout: 8000 });

        // Token should be removed
        const tokenAfter = await page.evaluate(() => localStorage.getItem('access_token'));
        expect(tokenAfter).toBeNull();
    });

    test('should not allow access to dashboard after logout', async ({ page }) => {
        // Logout
        await page.getByRole('button', { name: /Logout/ }).click();
        await expect(page).toHaveURL(/.*\/login/, { timeout: 8000 });

        // Try to directly access dashboard
        await page.goto('/dashboard');

        // Should be redirected back to login
        await expect(page).toHaveURL(/.*\/login/, { timeout: 8000 });
    });

    test('should not allow access to any dashboard sub-page after logout', async ({ page }) => {
        // Logout
        await page.getByRole('button', { name: /Logout/ }).click();
        await expect(page).toHaveURL(/.*\/login/, { timeout: 8000 });

        // Try to directly access users sub-page
        await page.goto('/dashboard/users');
        await expect(page).toHaveURL(/.*\/login/, { timeout: 8000 });
    });
});
