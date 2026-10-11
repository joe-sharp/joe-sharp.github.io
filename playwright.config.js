// @ts-check
const { defineConfig, devices } = require('@playwright/test');

// E2E_BASE_URL points the suite at an already-deployed site (e.g. a PR preview).
// Without it, the prebuilt _site is served locally.
const remote = process.env.E2E_BASE_URL;
// Not 4000, which `jekyll serve` uses; a dev server there would be reused by mistake.
const port = 4173;
const siteDir = process.env.E2E_SITE_DIR || '_site';
const baseURL = (remote || `http://127.0.0.1:${port}/`).replace(/\/?$/, '/');

module.exports = defineConfig({
  testDir: 'e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [['github'], ['html', { open: 'never' }]] : 'list',
  use: {
    baseURL,
    trace: 'retain-on-failure',
  },
  projects: [
    { name: 'desktop', use: { ...devices['Desktop Chrome'] } },
    { name: 'mobile', use: { ...devices['Pixel 5'] } },
  ],
  webServer: remote
    ? undefined
    : {
        command: `node e2e/static-server.js ${siteDir} ${port}`,
        url: baseURL,
        reuseExistingServer: !process.env.CI,
      },
});
