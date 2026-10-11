const { test, expect } = require('./fixtures');

test('unknown paths show the 404 page with its illustration', async ({ page }) => {
  const response = await page.goto('definitely-not-a-page/');

  expect(response.status()).toBe(404);
  const image = page.getByAltText(/milk carton/);
  await expect(image).toBeVisible();
  expect(await image.evaluate((img) => img.naturalWidth)).toBeGreaterThan(0);
});
