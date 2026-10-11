const base = require('@playwright/test');
const fs = require('fs');
const path = require('path');
const YAML = require('yaml');

// The generated deck is the source of truth for what the page should show.
const deck = Object.values(
  YAML.parse(fs.readFileSync(path.join(__dirname, '..', '_data', 'deck.yml'), 'utf8'))
);

exports.deck = deck;
exports.expect = base.expect;

exports.test = base.test.extend({
  // Keep tests hermetic: third-party hosts (fonts, Cloudinary art) are stubbed, and
  // anything the site itself gets wrong is collected on `problems`.
  problems: async ({ page, baseURL }, use) => {
    const origin = new URL(baseURL).origin;
    const problems = [];

    await page.route('**/*', (route) => {
      if (new URL(route.request().url()).origin === origin) return route.continue();
      return route.fulfill({ status: 200, body: '' });
    });

    page.on('pageerror', (error) => problems.push(`pageerror: ${error.message}`));
    page.on('response', (response) => {
      const url = response.url();
      if (url.startsWith(origin) && response.status() >= 400 && !response.request().isNavigationRequest()) {
        problems.push(`${response.status()} ${url}`);
      }
    });

    await use(problems);
  },
});
