import { Page } from '@playwright/test';

export async function login(page: Page) {
  await page.goto('http://localhost:3000/login');
  await page.locator('input[type="email"]').fill('admin@cropdiagnosis.com');
  await page.locator('input[type="password"]').fill('admin123');
  await page.getByRole('button', { name: /sign in/i }).click();
  await page.waitForURL('**/dashboard');
}