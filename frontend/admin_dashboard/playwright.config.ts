import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30000,
  workers: 1,   // 👈 run tests sequentially

  use: {
    baseURL: 'http://localhost:3000',
    headless: false,
    launchOptions: {
      slowMo: 1000,
    },
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
});