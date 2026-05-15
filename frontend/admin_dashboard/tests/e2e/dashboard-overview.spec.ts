import { test, expect } from '@playwright/test';

test.describe('Dashboard Overview', () => {
    test.beforeEach(async ({ page }) => {
        // Authenticate with real API
        await page.goto('/login');
        await page.getByPlaceholder('admin@example.com').fill('admin@cropdiagnosis.com');
        await page.getByPlaceholder('••••••••').fill('admin123');
        await page.getByRole('button', { name: 'Sign In' }).click();
        await expect(page).toHaveURL(/.*\/dashboard/, { timeout: 10000 });
    });

    test('should load and display key metric cards', async ({ page }) => {
        await expect(page.getByRole('heading', { name: 'Dashboard Overview' })).toBeVisible();
        await expect(page.getByText('System Operational').or(page.getByText('System Operational'))).toBeVisible();

        await expect(page.getByText('Total Farmers')).toBeVisible();
        await expect(page.getByText('Total Diagnoses')).toBeVisible();
        await expect(page.getByText('Questions Asked')).toBeVisible();
        await expect(page.getByText('Total Experts')).toBeVisible();
    });

    test('should display chart and side stats', async ({ page }) => {
        await expect(page.getByText('Activity Trends')).toBeVisible();
        await expect(page.getByText('Platform Stats')).toBeVisible();

        await expect(page.getByText('Verified Experts')).toBeVisible();
        await expect(page.getByText('Answered Questions')).toBeVisible();

        await expect(page.getByText('Weekly Growth')).toBeVisible();
    });
});
