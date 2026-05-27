import { chromium, FullConfig } from '@playwright/test';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../.env.test') });

const ADMIN_EMAIL    = process.env.ADMIN_EMAIL    ?? '';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? '';
const BASE_URL       = process.env.WEB_ADMIN_URL  ?? 'http://localhost:3000';

export default async function globalSetup(_config: FullConfig) {
  if (!ADMIN_EMAIL || !ADMIN_PASSWORD) return;

  const browser = await chromium.launch();
  const page    = await browser.newPage();

  await page.goto(`${BASE_URL}/login`);
  await page.waitForLoadState('domcontentloaded');
  await page.locator('input[type="email"], input[placeholder*="admin"]').fill(ADMIN_EMAIL);
  await page.locator('input[type="password"]').fill(ADMIN_PASSWORD);
  await page.getByRole('button', { name: /sign in/i }).click();
  await page.waitForURL(/\/dashboard/, { timeout: 30_000 });

  // Save authenticated browser storage so every test can skip login
  await page.context().storageState({ path: 'auth.json' });
  await browser.close();
}
