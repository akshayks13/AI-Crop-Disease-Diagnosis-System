import { test, expect } from '@playwright/test';
import { login } from './utils/auth';

test('Admin Login - End to End Test', async ({ page }) => {

  await login(page);

  await expect(page.getByText('Dashboard Overview')).toBeVisible();
});