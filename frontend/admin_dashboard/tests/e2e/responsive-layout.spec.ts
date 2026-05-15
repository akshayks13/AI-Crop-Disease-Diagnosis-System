import { test, expect, type Page } from '@playwright/test';

// Mobile viewport dimensions
const MOBILE_VIEWPORT = { width: 375, height: 812 }; // iPhone 12
const TABLET_VIEWPORT = { width: 768, height: 1024 }; // iPad
const DESKTOP_VIEWPORT = { width: 1440, height: 900 }; // Desktop

async function loginAsAdmin(page: Page) {
    await page.goto('/login');
    await page.getByPlaceholder('admin@example.com').fill('admin@cropdiagnosis.com');
    await page.getByPlaceholder('••••••••').fill('admin123');
    await page.getByRole('button', { name: 'Sign In' }).click();
    await expect(page).toHaveURL(/.*\/dashboard/, { timeout: 10000 });
}

test.describe('Responsive Layout', () => {
    test('login page renders correctly on mobile', async ({ page }) => {
        await page.setViewportSize(MOBILE_VIEWPORT);
        await page.goto('/login');

        // Login form should be visible on mobile
        await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible();
        await expect(page.getByPlaceholder('admin@example.com')).toBeVisible();
        await expect(page.getByPlaceholder('••••••••')).toBeVisible();
        await expect(page.getByRole('button', { name: 'Sign In' })).toBeVisible();
    });

    test('login page renders correctly on tablet', async ({ page }) => {
        await page.setViewportSize(TABLET_VIEWPORT);
        await page.goto('/login');

        await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible();
        await expect(page.getByRole('button', { name: 'Sign In' })).toBeVisible();
    });

    test('login page renders correctly on desktop', async ({ page }) => {
        await page.setViewportSize(DESKTOP_VIEWPORT);
        await page.goto('/login');

        await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible();
        await expect(page.getByRole('button', { name: 'Sign In' })).toBeVisible();
    });

    test('dashboard layout renders on desktop viewport', async ({ page }) => {
        await page.setViewportSize(DESKTOP_VIEWPORT);
        await loginAsAdmin(page);

        // Sidebar should be visible on desktop
        await expect(page.getByText('Crop Admin')).toBeVisible();
        await expect(page.getByText('Management Portal')).toBeVisible();

        // Dashboard heading
        await expect(page.getByRole('heading', { name: 'Dashboard Overview' })).toBeVisible();

        // Metric cards grid should render
        await expect(page.getByText('Total Farmers')).toBeVisible();
        await expect(page.getByText('Total Diagnoses')).toBeVisible();
    });

    test('dashboard metric cards are visible on tablet', async ({ page }) => {
        await page.setViewportSize(TABLET_VIEWPORT);
        await loginAsAdmin(page);

        await expect(page.getByRole('heading', { name: 'Dashboard Overview' })).toBeVisible();
        await expect(page.getByText('Total Farmers')).toBeVisible();
    });

    test('page title is set correctly for SEO', async ({ page }) => {
        await page.goto('/login');
        // Page should have a title
        const title = await page.title();
        expect(title.length).toBeGreaterThan(0);
    });
});
