import { test, expect } from '@playwright/test';

test.describe('Expert Approval Management', () => {
    test.beforeEach(async ({ page }) => {
        // Authenticate with real API
        await page.goto('/login');
        await page.getByPlaceholder('admin@example.com').fill('admin@cropdiagnosis.com');
        await page.getByPlaceholder('••••••••').fill('admin123');
        await page.getByRole('button', { name: 'Sign In' }).click();
        await expect(page).toHaveURL(/.*\/dashboard/, { timeout: 10000 });

        await page.goto('/dashboard/experts');
    });

    test('should display experts page correctly', async ({ page }) => {
        await expect(page.getByRole('heading', { name: 'Expert Approval' })).toBeVisible();
        await expect(page.getByText(/pending/i).first()).toBeVisible();
    });
});
