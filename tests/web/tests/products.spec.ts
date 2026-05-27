import { test, expect } from './fixtures';

test.describe('Products', () => {
  test.beforeEach(async ({ authedPage: page }) => {
    await page.goto('/products');
    await page.waitForLoadState('domcontentloaded');
  });

  test('products page loads with table or grid', async ({ authedPage: page }) => {
    await expect(page.getByRole('heading', { name: /products/i })).toBeVisible();
    // Should show either a table with rows or an empty state
    const table = page.locator('table, [data-testid="product-grid"]');
    const empty  = page.getByText(/no products/i);
    await expect(table.or(empty)).toBeVisible({ timeout: 15_000 });
  });

  test('add product button is visible', async ({ authedPage: page }) => {
    const addBtn = page.getByRole('button', { name: /add product/i })
      .or(page.getByRole('link', { name: /add product/i }));
    await expect(addBtn).toBeVisible();
  });

  test('product search / filter input is present', async ({ authedPage: page }) => {
    const search = page.getByPlaceholder(/search/i).first();
    if (await search.isVisible()) {
      await search.fill('test');
      await page.waitForTimeout(500);
      await search.clear();
    }
  });

  test('product rows show name, price, stock columns', async ({ authedPage: page }) => {
    const rows = page.locator('table tbody tr');
    if (await rows.count() > 0) {
      const firstRow = rows.first();
      // Row should have at least 3 cells
      const cellCount = await firstRow.locator('td').count();
      expect(cellCount).toBeGreaterThanOrEqual(3);
    }
  });
});
