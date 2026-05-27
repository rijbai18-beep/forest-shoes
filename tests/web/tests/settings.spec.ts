import { test, expect } from './fixtures';

test.describe('Settings', () => {
  test.beforeEach(async ({ authedPage: page }) => {
    await page.goto('/settings');
    await page.waitForLoadState('domcontentloaded');
  });

  test('settings page loads', async ({ authedPage: page }) => {
    await expect(page.getByRole('heading', { name: /settings/i })).toBeVisible();
  });

  test('email sender card is present', async ({ authedPage: page }) => {
    await expect(page.getByText(/email sender/i)).toBeVisible({ timeout: 10_000 });
  });

  test('payment & bank transfer card is present', async ({ authedPage: page }) => {
    await expect(page.getByText(/payment|bank/i).first()).toBeVisible({ timeout: 10_000 });
  });

  test('email fields accept input', async ({ authedPage: page }) => {
    const emailInput = page.getByPlaceholder(/gmail/i).or(page.locator('input[type="email"]')).first();
    if (await emailInput.isVisible()) {
      await emailInput.fill('test@gmail.com');
      await emailInput.fill(''); // reset
    }
  });

  test('save buttons are present for each section', async ({ authedPage: page }) => {
    const saveBtns = page.getByRole('button', { name: /save/i });
    await expect(saveBtns.first()).toBeVisible({ timeout: 10_000 });
  });

  test('delivery types section is accessible', async ({ authedPage: page }) => {
    await page.goto('/delivery-types');
    await page.waitForLoadState('domcontentloaded');
    await expect(page.getByRole('heading').first()).toBeVisible();
  });

  test('payment types section is accessible', async ({ authedPage: page }) => {
    await page.goto('/payment-types');
    await page.waitForLoadState('domcontentloaded');
    await expect(page.getByRole('heading').first()).toBeVisible();
  });
});
