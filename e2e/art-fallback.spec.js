const fs = require('fs');
const path = require('path');
const { test, expect } = require('./fixtures');

const artDir = path.join(__dirname, '..', 'images', 'art');
const fallback = /\/images\/art\/[0-9a-f]{32}\.webp$/;

// Serves the GitHub copy as if it were the Cloudinary original.
const serveLocalCopy = (route) => {
  const id = route.request().url().match(/([0-9a-f]{32})\.jpg$/)[1];
  return route.fulfill({ path: path.join(artDir, `${id}.webp`), contentType: 'image/webp' });
};

test.describe('card art fallback', () => {
  test('keeps Cloudinary art while Cloudinary is up', async ({ page }) => {
    await page.route(/res\.cloudinary\.com/, serveLocalCopy);

    await page.goto('./');

    const hrefs = await page.locator('defs image').evaluateAll((els) => els.map((el) => el.getAttribute('href')));
    expect(hrefs.length).toBeGreaterThan(0);
    for (const href of hrefs) expect(href).toMatch(/res\.cloudinary\.com/);
  });

  test('switches every card to the GitHub copy when Cloudinary fails', async ({ page }) => {
    await page.route(/res\.cloudinary\.com/, (route) => route.fulfill({ status: 503, body: '' }));

    await page.goto('./');

    const images = page.locator('defs image');
    await expect(images.first()).toHaveAttribute('href', fallback);
    const hrefs = await images.evaluateAll((els) => els.map((el) => el.getAttribute('href')));
    expect(hrefs.length).toBeGreaterThan(0);
    for (const href of hrefs) {
      expect(href).toMatch(fallback);
      const response = await page.request.get(new URL(href, page.url()).toString());
      expect(response.status()).toBe(200);
    }
  });
});
