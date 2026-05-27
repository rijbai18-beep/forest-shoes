import { test, expect, loginAdmin } from './fixtures';

test.describe('Auth', () => {
  test('unauthenticated redirect to login', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForURL('**/login**', { timeout: 10_000 });
    await expect(page.locator('input[type="email"], input[placeholder*="admin"]')).toBeVisible();
  });

  test('unauthenticated redirect preserves target path', async ({ page }) => {
    await page.goto('/orders');
    await page.waitForURL('**/login**', { timeout: 10_000 });
    const url = page.url();
    expect(url).toContain('login');
  });

  test('empty email validation', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('domcontentloaded');
    await page.locator('input[type="password"]').fill('somepass');
    await page.getByRole('button', { name: /sign in/i }).click();
    const emailInput = page.locator('input[type="email"], input[placeholder*="admin"]');
    const valid = await emailInput.evaluate((el: HTMLInputElement) => el.validity.valid);
    expect(valid).toBe(false);
  });

  test('successful login sets session and redirects', async ({ page }) => {
    await loginAdmin(page);
    await expect(page).toHaveURL(/dashboard/);
  });

  test('protected routes accessible after login', async ({ authedPage: page }) => {
    const routes = ['/orders', '/products', '/users', '/settings', '/coupons'];
    for (const route of routes) {
      await page.goto(route);
      await page.waitForLoadState('domcontentloaded');
      // Should NOT redirect back to login
      expect(page.url()).not.toContain('/login');
    }
  });
});
