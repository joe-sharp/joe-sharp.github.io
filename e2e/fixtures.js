const base = require('@playwright/test');
const fs = require('fs');
const path = require('path');
const YAML = require('yaml');

// The generated deck is the source of truth for what the page should show.
const deck = Object.values(
  YAML.parse(fs.readFileSync(path.join(__dirname, '..', '_data', 'deck.yml'), 'utf8'))
);

const artDir = path.join(__dirname, '..', 'images', 'art');

exports.deck = deck;
exports.expect = base.expect;

exports.test = base.test.extend({
  // Keep tests hermetic: Cloudinary art is answered with the mirrored GitHub copy, other
  // third-party hosts (fonts) are stubbed, and anything the site itself gets wrong is
  // collected on `problems`. Tests can override the stubs with their own page.route.
  problems: [
    async ({ page, baseURL }, use) => {
      const origin = new URL(baseURL).origin;
      const problems = [];

      await page.route('**/*', (route) => {
        const url = route.request().url();
        if (new URL(url).origin === origin) return route.continue();
        const art = url.match(/res\.cloudinary\.com\/.*([0-9a-f]{32})\.jpg$/);
        if (art) return route.fulfill({ path: path.join(artDir, `${art[1]}.webp`), contentType: 'image/webp' });
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
    { auto: true },
  ],
});
