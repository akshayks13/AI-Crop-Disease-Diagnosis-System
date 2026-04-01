import { test, expect } from '@playwright/test';

test('Login should fail with wrong password', async ({ page }) => {

  await page.goto('http://localhost:3000/login');

  await page.locator('input[type="email"]').fill('admin@cropdiagnosis.com');
  await page.locator('input[type="password"]').fill('wrongpassword');

  await page.getByRole('button', { name: /sign in/i }).click();

  // Make sure we stay on login page
  await expect(page).toHaveURL(/login/);
});