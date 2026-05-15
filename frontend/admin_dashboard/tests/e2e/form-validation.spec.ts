import { test, expect } from '@playwright/test';

test.describe('Login Form Validation', () => {
    test.beforeEach(async ({ page }) => {
        await page.goto('/login');
    });

    test('should show error when submitting empty form', async ({ page }) => {
        // Click Sign In without filling anything
        await page.getByRole('button', { name: 'Sign In' }).click();

        // Should still be on login page
        await expect(page).toHaveURL(/.*\/login/);

        // HTML5 required field validation — form should not submit
        // The email input should be focused / show validation
        const emailInput = page.getByPlaceholder('admin@example.com');
        await expect(emailInput).toBeVisible();
    });

    test('should show error when submitting only email (no password)', async ({ page }) => {
        await page.getByPlaceholder('admin@example.com').fill('admin@cropdiagnosis.com');
        await page.getByRole('button', { name: 'Sign In' }).click();

        // Should still be on login page (password required)
        await expect(page).toHaveURL(/.*\/login/);
    });

    test('should show error for wrong credentials', async ({ page }) => {
        // Wait for the API response so we know the error has been processed
        const responsePromise = page.waitForResponse('**/auth/login');

        await page.getByPlaceholder('admin@example.com').fill('wrong@email.com');
        await page.getByPlaceholder('••••••••').fill('wrongpassword');
        await page.getByRole('button', { name: 'Sign In' }).click();

        // Wait for backend to respond — should be 401 Unauthorized
        const response = await responsePromise;
        expect(response.status()).toBe(401);

        // Should stay on login page (not navigate to dashboard)
        await expect(page).toHaveURL(/.*\/login/);
    });

    test('should show error for invalid email format', async ({ page }) => {
        await page.getByPlaceholder('admin@example.com').fill('not-an-email');
        await page.getByPlaceholder('••••••••').fill('admin123');
        await page.getByRole('button', { name: 'Sign In' }).click();

        // HTML5 email validation should prevent submission
        await expect(page).toHaveURL(/.*\/login/);
    });

    test('should show error for correct email but wrong password', async ({ page }) => {
        // Wait for the API response so we know the error has been processed
        const responsePromise = page.waitForResponse('**/auth/login');

        await page.getByPlaceholder('admin@example.com').fill('admin@cropdiagnosis.com');
        await page.getByPlaceholder('••••••••').fill('wrongpassword');
        await page.getByRole('button', { name: 'Sign In' }).click();

        // Wait for backend to respond — should be 401 Unauthorized
        const response = await responsePromise;
        expect(response.status()).toBe(401);

        // Should stay on login page (not navigate to dashboard)
        await expect(page).toHaveURL(/.*\/login/);
    });

    test('should show loading state while submitting', async ({ page }) => {
        // Slow down the API response to see loading state
        await page.route('**/auth/login', async (route) => {
            await new Promise((resolve) => setTimeout(resolve, 2000));
            await route.continue();
        });

        await page.getByPlaceholder('admin@example.com').fill('admin@cropdiagnosis.com');
        await page.getByPlaceholder('••••••••').fill('admin123');

        // Find submit button by type — name changes to spinner during loading
        const submitButton = page.locator('button[type="submit"]');
        await submitButton.click();

        // During loading, the button becomes disabled (loading=true sets disabled={loading})
        await expect(submitButton).toBeDisabled({ timeout: 3000 });
    });

    test('should successfully login with correct admin credentials', async ({ page }) => {
        await page.getByPlaceholder('admin@example.com').fill('admin@cropdiagnosis.com');
        await page.getByPlaceholder('••••••••').fill('admin123');
        await page.getByRole('button', { name: 'Sign In' }).click();

        // Should redirect to dashboard
        await expect(page).toHaveURL(/.*\/dashboard/, { timeout: 10000 });

        // Token should be saved
        const token = await page.evaluate(() => localStorage.getItem('access_token'));
        expect(token).toBeTruthy();
    });
});
