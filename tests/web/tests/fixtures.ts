import { test as base, Page, expect } from '@playwright/test';

export { expect };

// Credentials from .env.test
export const ADMIN_EMAIL    = process.env.ADMIN_EMAIL    ?? 'admin@forestshoes.com';
export const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? 'Admin@1234';

// Shared login helper — call once per test that needs auth
export async function loginAdmin(page: Page) {
  await page.goto('/login');
  await page.waitForLoadState('domcontentloaded');
  // Labels are <label> text without for= association; select by input type/placeholder
  await page.locator('input[type="email"], input[placeholder*="admin"]').fill(ADMIN_EMAIL);
  await page.locator('input[type="password"]').fill(ADMIN_PASSWORD);
  await page.getByRole('button', { name: /sign in/i }).click();
  await page.waitForURL('**/dashboard', { timeout: 20_000 });
}

// Extended test fixture with auto-login
export const test = base.extend<{ authedPage: Page }>({
  authedPage: async ({ page }, use) => {
    await loginAdmin(page);
    await use(page);
  },
});
