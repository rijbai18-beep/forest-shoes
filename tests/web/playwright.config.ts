import { defineConfig, devices } from '@playwright/test';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../.env.test') });

const BASE_URL = process.env.WEB_ADMIN_URL ?? 'http://localhost:3000';

export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: [
    ['html', { outputFolder: '../reports/web', open: 'never' }],
    ['junit', { outputFile: '../reports/web/results.xml' }],
    ['list'],
  ],
  use: {
    baseURL: BASE_URL,
    headless: !process.env.HEADED,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 15_000,
    navigationTimeout: 30_000,
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  // Run dev server if not already running
  webServer: process.env.SKIP_DEV_SERVER ? undefined : {
    command: 'cd ../../web_admin && npm run dev',
    url: BASE_URL,
    reuseExistingServer: true,
    timeout: 60_000,
  },
});
