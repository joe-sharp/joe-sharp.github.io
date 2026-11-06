const { test, expect, deck } = require('./fixtures');

const opacity = (locator) => locator.evaluate((el) => getComputedStyle(el).opacity);
const scrollY = (page) => page.evaluate(() => window.scrollY);

// One visit covers everything the default home page does, in the order a visitor
// meets it: the static page as served, then dealing the cards by scrolling, then
// leaving. Only the refresh check needs a second load.
test('home page', async ({ page, problems, isMobile }) => {
  await page.goto('./');

  await test.step('masthead, about and projects sections render', async () => {
    await expect(page).toHaveTitle(/joe-sharp/i);
    await expect(page.locator('.avatar')).toBeVisible();
    // The title and tagline only show in the sidebar masthead (801px and up).
    await expect(page.locator('.site-title')).toBeVisible({ visible: !isMobile });
    await expect(page.getByRole('heading', { name: 'About' })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Projects' })).toBeVisible();
  });

  await test.step('describes a projects portfolio, not a blog', async () => {
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

  await test.step('has no horizontal scroll', async () => {
    const overflow = await page.evaluate(
      () => document.documentElement.scrollWidth - document.documentElement.clientWidth
    );
    expect(overflow).toBeLessThanOrEqual(0);
  });

  const cards = page.locator('.project-card');

  await test.step('shows one card per deck entry linking to its repository', async () => {
    await expect(cards).toHaveCount(deck.length);
    for (const [i, entry] of deck.entries()) {
      const card = cards.nth(i);
      await expect(card).toHaveAttribute('href', entry.flavor_text.split('\n')[0]);
      await expect(card).toHaveAttribute('target', '_blank');
      await expect(card).toHaveAttribute('rel', /noopener/);
      await expect(card).toHaveAttribute('aria-label', entry.name);
    }
  });

  await test.step('every card draws a card from the inlined sprite', async () => {
    const missing = await page.evaluate(() =>
      [...document.querySelectorAll('.project-card use')]
        .map((use) => use.getAttribute('href'))
        .filter((href) => !document.querySelector(href))
    );
    expect(missing).toEqual([]);
  });

  // Must run before anything scrolls: the last card is below the fold and undealt.
  await test.step('cards wait face down until scrolled into view', async () => {
    await expect(page.locator('.projects-cards')).toHaveClass(/deal-armed/);
    await expect(cards.last()).not.toHaveClass(/is-dealt/);
    expect(await opacity(cards.last())).toBe('0');
  });

  await test.step('every card is dealt and flipped once scrolled into view', async () => {
    for (let i = 0; i < deck.length; i++) {
      await cards.nth(i).scrollIntoViewIfNeeded();
    }
    for (let i = 0; i < deck.length; i++) {
      await expect(cards.nth(i)).toHaveClass(/is-dealt/);
      await expect(cards.nth(i)).toHaveClass(/is-flipped/, { timeout: 15_000 });
    }
    expect(await opacity(cards.last())).toBe('1');
  });

  // Checked late on purpose: the fallback swaps after a probe or a 6s timeout, so by
  // now a wrong swap would have happened.
  await test.step('keeps Cloudinary art while Cloudinary is up', async () => {
    const hrefs = await page.locator('defs image').evaluateAll((els) => els.map((el) => el.getAttribute('href')));
    expect(hrefs.length).toBeGreaterThan(0);
    for (const href of hrefs) expect(href).toMatch(/res\.cloudinary\.com/);
  });

  if (isMobile) {
    // The back-to-top button is only shown at 800px and below.
    await test.step('back to top scrolls up', async () => {
      await page.locator('#to-top').scrollIntoViewIfNeeded();
      await expect.poll(() => scrollY(page)).toBeGreaterThan(0);
      await page.locator('#to-top').click();
      await expect.poll(() => scrollY(page)).toBe(0);
    });
  }

  await test.step('refreshing starts at the top', async () => {
    await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
    await expect.poll(() => scrollY(page)).toBeGreaterThan(0);
    await page.reload();
    await expect.poll(() => scrollY(page)).toBe(0);
  });

  expect(problems).toEqual([]);
});

// Both behaviours are decided once, as the page loads, so this needs its own visit.
// Loading straight onto the hash matters: going to #projects from the page already
// open is an in-page jump that never re-runs the scroll-to-top script.
test.describe('with reduced motion, opened on a hash link', () => {
  test.use({ reducedMotion: 'reduce' });

  test('shows the cards immediately and jumps to the anchor', async ({ page, problems }) => {
    await page.goto('./#projects');

    await test.step('hash links still jump', async () => {
      await expect.poll(() => scrollY(page)).toBeGreaterThan(0);
    });

    await test.step('cards are shown without dealing them', async () => {
      const first = page.locator('.project-card').first();
      await expect(page.locator('.projects-cards')).not.toHaveClass(/deal-armed/);
      await expect(first).not.toHaveClass(/is-dealt/);
      expect(await opacity(first)).toBe('1');
      await expect(first).toBeVisible();
    });

    expect(problems).toEqual([]);
  });
});
