import { test, expect, type Page } from '@playwright/test';

// Helper: login as admin before each test
async function loginAsAdmin(page: Page) {
    await page.goto('/login');
    await page.getByPlaceholder('admin@example.com').fill('admin@cropdiagnosis.com');
    await page.getByPlaceholder('••••••••').fill('admin123');
    await page.getByRole('button', { name: 'Sign In' }).click();
    await expect(page).toHaveURL(/.*\/dashboard/, { timeout: 15000 });
}

test.describe('Sidebar Navigation', () => {
    test.describe.configure({ retries: 2 });

    test.beforeEach(async ({ page }) => {
        await loginAsAdmin(page);
    });

    test('should display sidebar with all nav items', async ({ page }) => {
        // Sidebar brand
        await expect(page.getByText('Crop Admin')).toBeVisible();
        await expect(page.getByText('Management Portal')).toBeVisible();

        // All nav links visible
        await expect(page.getByRole('link', { name: /Dashboard/ })).toBeVisible();
        await expect(page.getByRole('link', { name: /Expert Approval/ })).toBeVisible();
        await expect(page.getByRole('link', { name: /Users/ })).toBeVisible();
        await expect(page.getByRole('link', { name: /Questions/ })).toBeVisible();
        await expect(page.getByRole('link', { name: /Diagnoses/ })).toBeVisible();
        await expect(page.getByRole('link', { name: /Agronomy/ })).toBeVisible();
        await expect(page.getByRole('link', { name: /System Logs/ })).toBeVisible();

        // Logout button
        await expect(page.getByRole('button', { name: /Logout/ })).toBeVisible();
    });

    test('should navigate to Expert Approval page', async ({ page }) => {
        await page.getByRole('link', { name: /Expert Approval/ }).click();
        await expect(page).toHaveURL(/.*\/dashboard\/experts/, { timeout: 8000 });
        await expect(page.getByRole('heading', { name: /Expert/ })).toBeVisible();
    });

    test('should navigate to Users page', async ({ page }) => {
        await page.getByRole('link', { name: 'Users' }).click();
        await expect(page).toHaveURL(/.*\/dashboard\/users/, { timeout: 8000 });
        await expect(page.getByRole('heading', { name: /User/ })).toBeVisible();
    });

    test('should navigate to Questions page', async ({ page }) => {
        await page.getByRole('link', { name: /Questions/ }).click();
        await expect(page).toHaveURL(/.*\/dashboard\/questions/, { timeout: 8000 });
    });

    test('should navigate to Diagnoses page', async ({ page }) => {
        await page.getByRole('link', { name: /Diagnoses/ }).click();
        await expect(page).toHaveURL(/.*\/dashboard\/diagnoses/, { timeout: 8000 });
    });

    test('should navigate to Agronomy page', async ({ page }) => {
        await page.getByRole('link', { name: /Agronomy/ }).click();
        await expect(page).toHaveURL(/.*\/dashboard\/agronomy/, { timeout: 8000 });
    });

    test('should navigate to System Logs page', async ({ page }) => {
        await page.getByRole('link', { name: /System Logs/ }).click();
        await expect(page).toHaveURL(/.*\/dashboard\/logs/, { timeout: 8000 });
    });

    test('should highlight active nav item', async ({ page }) => {
        // Navigate to users — use domcontentloaded to handle Firefox redirect abort
        try {
            await page.goto('/dashboard/users', { waitUntil: 'domcontentloaded', timeout: 10000 });
        } catch {
            // Firefox may abort if Next.js does a client redirect — wait for stability
            await page.waitForURL(/.*\/dashboard/, { timeout: 5000 }).catch(() => { });
        }

        // The 'Users' link should have active styling (bg-indigo-600)
        const usersLink = page.getByRole('link', { name: 'Users' });
        await expect(usersLink).toHaveClass(/bg-indigo-600/, { timeout: 5000 });

        // Dashboard link should NOT be active
        const dashLink = page.getByRole('link', { name: 'Dashboard' });
        await expect(dashLink).not.toHaveClass(/bg-indigo-600/);
    });
});
