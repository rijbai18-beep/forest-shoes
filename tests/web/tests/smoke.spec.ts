import { test, expect, ADMIN_EMAIL, ADMIN_PASSWORD } from './fixtures';

// Helpers matching the actual login page DOM (labels are <label> text, not for= attr)
async function fillEmail(page: import('@playwright/test').Page, email: string) {
  await page.locator('input[type="email"], input[placeholder*="admin"]').fill(email);
}
async function fillPassword(page: import('@playwright/test').Page, pass: string) {
  await page.locator('input[type="password"]').fill(pass);
}
async function clickSignIn(page: import('@playwright/test').Page) {
  await page.getByRole('button', { name: /sign in/i }).click();
}

test.describe('Smoke @smoke', () => {
  test('login page renders', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('domcontentloaded');
    // Heading is "Welcome back" on the login form panel
    await expect(page.getByRole('heading', { name: /welcome back/i })).toBeVisible();
    await expect(page.locator('input[type="email"], input[placeholder*="admin"]')).toBeVisible();
    await expect(page.locator('input[type="password"]')).toBeVisible();
    await expect(page.getByRole('button', { name: /sign in/i })).toBeVisible();
  });

  test('invalid credentials shows error', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('domcontentloaded');
    await fillEmail(page, 'nobody@example.com');
    await fillPassword(page, 'wrongpassword');
    await clickSignIn(page);
    // Error div: bg-red-50 border border-red-200 wrapping a p.text-red-700
    const error = page.locator('div.bg-red-50, p.text-red-700').first();
    await expect(error).toBeVisible({ timeout: 12_000 });
  });

  test('admin can log in and reach dashboard @smoke', async ({ page }) => {
    test.setTimeout(90_000);
    await page.goto('/login');
    await page.waitForLoadState('domcontentloaded');
    await fillEmail(page, ADMIN_EMAIL);
    await fillPassword(page, ADMIN_PASSWORD);
    await clickSignIn(page);
    await page.waitForURL(/\/dashboard/, { timeout: 25_000 });
    // Dashboard h1 renders only after Firebase data loads — allow extra time
    await expect(page.getByRole('heading', { name: /dashboard/i })).toBeVisible({ timeout: 40_000 });
  });

  test('sidebar navigation links are present @smoke', async ({ authedPage: page }) => {
    const links = ['Dashboard', 'Orders', 'Products', 'Users', 'Coupons', 'Settings'];
    for (const link of links) {
      await expect(page.getByRole('link', { name: new RegExp(link, 'i') }).first()).toBeVisible();
    }
  });
});
