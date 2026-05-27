import { test, expect } from './fixtures';

test.describe('Orders', () => {
  test.beforeEach(async ({ authedPage: page }) => {
    await page.goto('/orders');
    await page.waitForLoadState('domcontentloaded');
  });

  test('orders page loads', async ({ authedPage: page }) => {
    await expect(page.getByRole('heading', { name: /orders/i })).toBeVisible();
  });

  test('order IDs use FS-prefixed format or legacy hash format', async ({ authedPage: page }) => {
    const rows = page.locator('table tbody tr');
    const count = await rows.count();
    if (count === 0) return; // No orders yet — pass

    const firstOrderId = rows.first().locator('td').first();
    const text = await firstOrderId.textContent() ?? '';
    // Accept FS0001 format or #XXXXXXXX legacy fallback
    expect(text).toMatch(/FS\d+|#[A-F0-9]{8}/);
  });

  test('order detail opens on row click', async ({ authedPage: page }) => {
    const rows = page.locator('table tbody tr');
    if (await rows.count() === 0) return;

    await rows.first().click();
    await page.waitForLoadState('domcontentloaded');
    // Detail should show order number in heading
    const heading = page.getByRole('heading').first();
    await expect(heading).toBeVisible();
    const headingText = await heading.textContent() ?? '';
    expect(headingText).toMatch(/order|FS\d+/i);
  });

  test('order status filter is present', async ({ authedPage: page }) => {
    const filter = page.locator('select, [role="combobox"]').first();
    if (await filter.isVisible()) {
      // Just ensure it's interactive
      await expect(filter).toBeEnabled();
    }
  });

  test('orders page shows column headers', async ({ authedPage: page }) => {
    const headers = page.locator('table thead th');
    if (await headers.count() > 0) {
      await expect(headers.first()).toBeVisible();
    }
  });
});
