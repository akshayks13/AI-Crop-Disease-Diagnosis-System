import { test, expect } from '@playwright/test';

test.describe('404 and Unknown Routes', () => {
    test('should load root URL without crashing', async ({ page }) => {
        await page.goto('/');

        // Root URL should load something — not a blank or error page
        await expect(page).not.toHaveURL('about:blank');

        // Page body should have content
        const body = await page.locator('body').textContent();
        expect(body?.length).toBeGreaterThan(0);

        // Title should be present
        const title = await page.title();
        expect(title.length).toBeGreaterThan(0);
    });

    test('should handle a completely unknown route gracefully', async ({ page }) => {
        await page.goto('/this-page-does-not-exist');

        // Should show a 404 page or redirect — not a white/broken page
        const body = await page.locator('body').textContent();
        expect(body?.length).toBeGreaterThan(0);

        // Title should be set (not empty)
        const title = await page.title();
        expect(title.length).toBeGreaterThan(0);
    });

    test('should handle unknown dashboard sub-route when authenticated', async ({ page }) => {
        // Login first
        await page.goto('/login');
        await page.getByPlaceholder('admin@example.com').fill('admin@cropdiagnosis.com');
        await page.getByPlaceholder('••••••••').fill('admin123');
        await page.getByRole('button', { name: 'Sign In' }).click();
        await expect(page).toHaveURL(/.*\/dashboard/, { timeout: 10000 });

        // Navigate to a non-existent dashboard sub-page
        // Use domcontentloaded to avoid Firefox NS_BINDING_ABORTED on redirect
        try {
            await page.goto('/dashboard/nonexistent-section', { waitUntil: 'domcontentloaded', timeout: 8000 });
        } catch {
            // Firefox may abort if Next.js redirects mid-load — that's acceptable
        }

        // Should not crash — page should have some content regardless
        const body = await page.locator('body').textContent();
        expect(body?.length).toBeGreaterThan(0);
    });

    test('should redirect unauthenticated users from /dashboard to /login', async ({ page }) => {
        // Ensure no token in storage
        await page.goto('/login'); // Just to init the page context
        await page.evaluate(() => localStorage.removeItem('access_token'));

        // Try to access dashboard directly
        await page.goto('/dashboard');

        // Should be redirected to login
        await expect(page).toHaveURL(/.*\/login/, { timeout: 8000 });
    });

    test('should redirect unauthenticated user from /dashboard/users to /login', async ({ page }) => {
        await page.goto('/login');
        await page.evaluate(() => localStorage.removeItem('access_token'));

        await page.goto('/dashboard/users');

        await expect(page).toHaveURL(/.*\/login/, { timeout: 8000 });
    });

    test('should redirect unauthenticated user from /dashboard/experts to /login', async ({ page }) => {
        await page.goto('/login');
        await page.evaluate(() => localStorage.removeItem('access_token'));

        await page.goto('/dashboard/experts');

        await expect(page).toHaveURL(/.*\/login/, { timeout: 8000 });
    });

    test('login page should be accessible without auth', async ({ page }) => {
        await page.goto('/login');

        // Login page should render correctly without auth
        await expect(page.getByRole('heading', { name: 'Welcome back' })).toBeVisible();
        await expect(page.getByRole('button', { name: 'Sign In' })).toBeVisible();
    });
});
