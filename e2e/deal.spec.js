const { test, expect, deck } = require('./fixtures');

const opacity = (locator) => locator.evaluate((el) => getComputedStyle(el).opacity);

test.describe('deal animation', () => {
  test('cards wait face down, then are dealt and flipped when scrolled into view', async ({ page }) => {
    await page.goto('./');
    const grid = page.locator('.projects-cards');
    const last = page.locator('.project-card').last();

    await expect(grid).toHaveClass(/deal-armed/);
    await expect(last).not.toHaveClass(/is-dealt/);
    expect(await opacity(last)).toBe('0');

    await last.scrollIntoViewIfNeeded();
    await expect(last).toHaveClass(/is-dealt/);
    await expect(last).toHaveClass(/is-flipped/, { timeout: 10_000 });
    expect(await opacity(last)).toBe('1');
  });

  test('every card is eventually dealt', async ({ page }) => {
    await page.goto('./');
    const cards = page.locator('.project-card');
    for (let i = 0; i < deck.length; i++) {
      await cards.nth(i).scrollIntoViewIfNeeded();
    }
    for (let i = 0; i < deck.length; i++) {
      await expect(cards.nth(i)).toHaveClass(/is-flipped/, { timeout: 15_000 });
    }
  });

  test.describe('with reduced motion', () => {
    test.use({ reducedMotion: 'reduce' });

    test('shows the cards immediately without dealing them', async ({ page }) => {
      await page.goto('./');
      const grid = page.locator('.projects-cards');
      const first = page.locator('.project-card').first();

      await expect(grid).not.toHaveClass(/deal-armed/);
      await expect(first).not.toHaveClass(/is-dealt/);
      expect(await opacity(first)).toBe('1');
      await expect(first).toBeVisible();
    });
  });
});
