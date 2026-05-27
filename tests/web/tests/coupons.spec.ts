import { test, expect } from './fixtures';

test.describe('Coupons', () => {
  test.beforeEach(async ({ authedPage: page }) => {
    await page.goto('/coupons');
    await page.waitForLoadState('domcontentloaded');
  });

  test('coupons page loads', async ({ authedPage: page }) => {
    await expect(page.getByRole('heading', { name: /coupon/i })).toBeVisible();
  });

  test('add coupon button is visible', async ({ authedPage: page }) => {
    const addBtn = page.getByRole('button', { name: /add coupon|create/i })
      .or(page.getByRole('link', { name: /add coupon|create/i }));
    await expect(addBtn).toBeVisible();
  });

  test('coupon table or empty state renders', async ({ authedPage: page }) => {
    const table = page.locator('table');
    const empty  = page.getByText(/no coupons/i);
    await expect(table.or(empty)).toBeVisible({ timeout: 10_000 });
  });
});
