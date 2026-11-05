const { test, expect } = require('./fixtures');

const rgb = (locator, property) => locator.evaluate((el, p) => getComputedStyle(el)[p], property);

test('unknown paths show the 404 page with its illustration', async ({ page }) => {
  const response = await page.goto('definitely-not-a-page/');

  expect(response.status()).toBe(404);
  const image = page.getByAltText(/milk carton/);
  await expect(image).toBeVisible();
  expect(await image.evaluate((img) => img.naturalWidth)).toBeGreaterThan(0);
});

// Request 404.html itself: on GitHub Pages an unknown path under a PR preview is
// answered by the production site's root 404.html, not the preview's copy.
// The colour scheme is a media query, so it can be switched without reloading.
test('404 page follows the colour scheme', async ({ page }) => {
  await page.emulateMedia({ colorScheme: 'light' });
  await page.goto('404.html');
  const body = page.locator('body');

  await test.step('light uses the light background', async () => {
    expect(await rgb(body, 'backgroundColor')).toBe('rgb(221, 221, 221)');
  });

  await test.step('dark uses a dark background with light text', async () => {
    await page.emulateMedia({ colorScheme: 'dark' });
    expect(await rgb(body, 'backgroundColor')).toBe('rgb(22, 18, 28)');
    expect(await rgb(body, 'color')).toBe('rgb(233, 223, 240)');
    await expect(page.getByRole('link', { name: 'Back to Home' })).toBeVisible();
  });

  await test.step('Back to Home returns to the projects site', async () => {
    await expect(page.getByRole('link', { name: 'Back to Home' })).toHaveAttribute('href', 'https://projects.joe-sharp.com/');
  });
});
