const { test, expect } = require('./fixtures');

const rgb = (locator, property) => locator.evaluate((el, p) => getComputedStyle(el)[p], property);

test('unknown paths show the 404 page with its illustration', async ({ page }) => {
  const response = await page.goto('definitely-not-a-page/');

  expect(response.status()).toBe(404);
  const image = page.getByAltText(/milk carton/);
  await expect(image).toBeVisible();
  expect(await image.evaluate((img) => img.naturalWidth)).toBeGreaterThan(0);
});

test.describe('404 colour scheme', () => {
  test.describe('light', () => {
    test.use({ colorScheme: 'light' });

    test('uses the light background', async ({ page }) => {
      await page.goto('definitely-not-a-page/');
      expect(await rgb(page.locator('body'), 'backgroundColor')).toBe('rgb(221, 221, 221)');
    });
  });

  test.describe('dark', () => {
    test.use({ colorScheme: 'dark' });

    test('uses a dark background with light text', async ({ page }) => {
      await page.goto('definitely-not-a-page/');
      expect(await rgb(page.locator('body'), 'backgroundColor')).toBe('rgb(22, 18, 28)');
      expect(await rgb(page.locator('body'), 'color')).toBe('rgb(233, 223, 240)');
      await expect(page.getByRole('link', { name: 'Back to Home' })).toBeVisible();
    });
  });
});
