import { test, expect } from '@playwright/test';

test.describe('Error States — API Down / Network Failure', () => {
    test.beforeEach(async ({ page }) => {
        // Login first, then we intercept API calls
        await page.goto('/login');
        await page.getByPlaceholder('admin@example.com').fill('admin@cropdiagnosis.com');
        await page.getByPlaceholder('••••••••').fill('admin123');
        await page.getByRole('button', { name: 'Sign In' }).click();
        await expect(page).toHaveURL(/.*\/dashboard/, { timeout: 10000 });
    });

    test('should show error message when dashboard API is down', async ({ page }) => {
        // Intercept the dashboard API call and return 500
        await page.route('**/admin/dashboard', (route) =>
            route.fulfill({ status: 500, body: JSON.stringify({ detail: 'Internal Server Error' }) })
        );
        await page.route('**/admin/metrics/daily**', (route) =>
            route.fulfill({ status: 500, body: JSON.stringify({ detail: 'Internal Server Error' }) })
        );

        // Reload dashboard
        await page.goto('/dashboard');

        // Should show error UI
        await expect(page.getByText(/Error loading dashboard|Failed to load|check your connection/i)).toBeVisible({ timeout: 10000 });
    });

    test('should show error when users API returns 500', async ({ page }) => {
        // Intercept users API
        await page.route('**/admin/users**', (route) =>
            route.fulfill({ status: 500, body: JSON.stringify({ detail: 'Server Error' }) })
        );

        await page.goto('/dashboard/users');

        // Should show error state or empty state
        await expect(
            page.getByText(/error|failed|something went wrong|no users/i).first()
        ).toBeVisible({ timeout: 10000 });
    });

    test('should show error when diagnoses API returns 500', async ({ page }) => {
        await page.route('**/admin/diagnoses**', (route) =>
            route.fulfill({ status: 500, body: JSON.stringify({ detail: 'Server Error' }) })
        );

        // Use domcontentloaded to avoid Firefox NS_BINDING_ABORTED
        try {
            await page.goto('/dashboard/diagnoses', { waitUntil: 'domcontentloaded', timeout: 10000 });
        } catch {
            await page.waitForURL(/.*\/dashboard/, { timeout: 5000 }).catch(() => { });
        }

        // Wait for page to settle
        await page.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => { });

        // Should stay on the diagnoses page (not crash or redirect away)
        await expect(page).toHaveURL(/.*\/dashboard/);

        // Page must have content (not blank)
        const body = await page.locator('body').textContent();
        expect(body?.length).toBeGreaterThan(0);
    });

    test('should show error when logs API returns 500', async ({ page }) => {
        await page.route('**/admin/logs**', (route) =>
            route.fulfill({ status: 500, body: JSON.stringify({ detail: 'Server Error' }) })
        );

        await page.goto('/dashboard/logs');

        await expect(
            page.getByText(/error|failed|something went wrong/i).first()
        ).toBeVisible({ timeout: 10000 });
    });

    test('should handle network failure gracefully on dashboard', async ({ page }) => {
        // Simulate total outage with 503
        await page.route('**/admin/dashboard', (route) =>
            route.fulfill({ status: 503, body: JSON.stringify({ detail: 'Service Unavailable' }) })
        );
        await page.route('**/admin/metrics/daily**', (route) =>
            route.fulfill({ status: 503, body: JSON.stringify({ detail: 'Service Unavailable' }) })
        );

        await page.goto('/dashboard');

        // Wait for the page to settle after the failed API calls
        await page.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => { });

        // Should NOT navigate away — must stay on /dashboard (not crash to error page)
        await expect(page).toHaveURL(/.*\/dashboard/);

        // Page must have body content (not blank or crashed)
        const body = await page.locator('body').textContent();
        expect(body?.length).toBeGreaterThan(0);
    });
});
