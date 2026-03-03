import { test, expect } from '@playwright/test';
import { login } from './utils/auth';

test('Admin logout flow', async ({ page }) => {

  await login(page);

  await page.getByText(/logout/i).click();

  await expect(page).toHaveURL(/login/);
});