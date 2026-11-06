const { test, expect } = require('./fixtures');

const fallback = /\/images\/art\/[0-9a-f]{32}\.webp$/;

// The Cloudinary-up case is covered by the home page visit, where the fixtures serve
// the art. This one needs its own visit because Cloudinary has to fail from the start.
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
