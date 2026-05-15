import { test, expect } from '@playwright/test';

test.describe('Diagnoses & Reports', () => {
    test.describe.configure({ retries: 2 });

    test.beforeEach(async ({ page }) => {
        // Authenticate with real API
        await page.goto('/login');
        await page.getByPlaceholder('admin@example.com').fill('admin@cropdiagnosis.com');
        await page.getByPlaceholder('••••••••').fill('admin123');
        await page.getByRole('button', { name: 'Sign In' }).click();
        await expect(page).toHaveURL(/.*\/dashboard/, { timeout: 15000 });

        await page.goto('/dashboard/diagnoses');
    });

    test('should display diagnoses page correctly', async ({ page }) => {
        await expect(page.getByRole('heading', { name: 'Diagnoses & Reports' })).toBeVisible({ timeout: 10000 });
        await expect(page.getByText('Monitor AI diagnosis activity')).toBeVisible();
    });
});
