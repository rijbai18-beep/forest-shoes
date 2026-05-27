import { test as base, Page, Browser, expect } from '@playwright/test';

export { expect };

// Credentials from .env.test
export const ADMIN_EMAIL    = process.env.ADMIN_EMAIL    ?? 'admin@forestshoes.com';
export const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'Admin@1234';

// Full login helper — drives the real login UI.
export async function loginAdmin(page: Page) {
  await page.goto('/login');
  await page.waitForLoadState('domcontentloaded');
  await page.locator('input[type="email"], input[placeholder*="admin"]').fill(ADMIN_EMAIL);
  await page.locator('input[type="password"]').fill(ADMIN_PASSWORD);
  await page.getByRole('button', { name: /sign in/i }).click();
  await page.waitForURL(/\/dashboard/, { timeout: 25_000 });
}

// Worker-scoped fixture — logs in ONCE for the entire test run (1 worker).
// Firebase uses IndexedDB so storageState can't capture it; we log in once and
// reuse the same browser context across all tests that need auth.
export const test = base.extend<{ authedPage: Page }, { workerAuth: { page: Page; browser: Browser } }>({
  workerAuth: [async ({ browser }, use) => {
    const context = await browser.newContext();
    const page    = await context.newPage();
    await loginAdmin(page);
    await use({ page, browser });
    await context.close();
  }, { scope: 'worker' }],

  authedPage: async ({ workerAuth }, use) => {
    await use(workerAuth.page);
  },
});
