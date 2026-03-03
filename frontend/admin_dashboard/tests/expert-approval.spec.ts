import { test, expect } from '@playwright/test';
import { login } from './utils/auth';

test('Approve Expert Flow', async ({ page }) => {

  await login(page);

  await page.getByText('Expert Approval').click();

  await expect(page).toHaveURL(/expert/);
});