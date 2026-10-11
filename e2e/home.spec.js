const { test, expect, deck } = require('./fixtures');

test.describe('home page', () => {
  test('renders the masthead, about and projects sections without errors', async ({ page, problems, isMobile }) => {
    await page.goto('./');

    await expect(page).toHaveTitle(/joe-sharp/i);
    await expect(page.locator('.avatar')).toBeVisible();
    // The title and tagline only show in the sidebar masthead (801px and up).
    await expect(page.locator('.site-title')).toBeVisible({ visible: !isMobile });
    await expect(page.getByRole('heading', { name: 'About' })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Projects' })).toBeVisible();
    expect(problems).toEqual([]);
  });

  test('describes a projects portfolio, not a blog', async ({ page }) => {
    await page.goto('./');

    const meta = (selector) => page.locator(selector).getAttribute('content');
    expect(await meta('meta[name="description"]')).toMatch(/Staff Software Engineer/);
    expect(await meta('meta[property="og:description"]')).toMatch(/Staff Software Engineer/);
    expect(await meta('meta[property="og:url"]')).toMatch(/^https:\/\/projects\.joe-sharp\.com\//);
    expect(await page.content()).not.toMatch(/blog/i);

    // The share image must exist on this build.
    const image = await meta('meta[property="og:image"]');
    expect(new URL(image).pathname.endsWith('/images/joe-sharp.png')).toBe(true);
    expect((await page.request.get('images/joe-sharp.png')).status()).toBe(200);
  });

  test('has no horizontal scroll', async ({ page }) => {
    await page.goto('./');
    const overflow = await page.evaluate(
      () => document.documentElement.scrollWidth - document.documentElement.clientWidth
    );
    expect(overflow).toBeLessThanOrEqual(0);
  });

  test('refreshing starts at the top, but hash links still jump', async ({ page }) => {
    await page.goto('./');
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await expect.poll(() => page.evaluate(() => window.scrollY)).toBeGreaterThan(0);

    await page.reload();
    await expect.poll(() => page.evaluate(() => window.scrollY)).toBe(0);

    await page.goto('./#projects');
    await expect.poll(() => page.evaluate(() => window.scrollY)).toBeGreaterThan(0);
  });

  test('back to top scrolls up', async ({ page, isMobile }) => {
    test.skip(!isMobile, 'The back-to-top button is only shown at 800px and below');
    await page.goto('./');
    await page.locator('#to-top').scrollIntoViewIfNeeded();
    await expect.poll(() => page.evaluate(() => window.scrollY)).toBeGreaterThan(0);

    await page.locator('#to-top').click();
    await expect.poll(() => page.evaluate(() => window.scrollY)).toBe(0);
  });
});

test.describe('project cards', () => {
  test('shows one card per deck entry linking to its repository', async ({ page }) => {
    await page.goto('./');
    const cards = page.locator('.project-card');

    await expect(cards).toHaveCount(deck.length);
    for (const [i, entry] of deck.entries()) {
      const card = cards.nth(i);
      await expect(card).toHaveAttribute('href', entry.flavor_text.split('\n')[0]);
      await expect(card).toHaveAttribute('target', '_blank');
      await expect(card).toHaveAttribute('rel', /noopener/);
      await expect(card).toHaveAttribute('aria-label', entry.name);
    }
  });

  test('every card draws a card from the inlined sprite', async ({ page }) => {
    await page.goto('./');
    const missing = await page.evaluate(() =>
      [...document.querySelectorAll('.project-card use')]
        .map((use) => use.getAttribute('href'))
        .filter((href) => !document.querySelector(href))
    );
    expect(missing).toEqual([]);
  });
});
