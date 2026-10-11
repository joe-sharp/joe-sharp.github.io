# Joe Sharp's Personal Site ✨

A Jekyll-powered portfolio: an About section and a grid of my GitHub projects, each shown as a collectible card.

## 🚀 Quick Start

```bash
# Install dependencies
bundle install

# Start the development server
bundle exec jekyll serve
```

## 🧪 Development

```bash
bundle exec rake test        # unit tests
bundle exec rake build       # production-parity build into _site
npm ci && npx playwright install chromium   # once, for the E2E tests
bundle exec rake e2e         # build, then run the Playwright tests
bundle exec rake deck        # regenerate the project cards from GitHub
bundle exec rake deck:sprite # rebuild only the sprite from _data/deck.yml
```

The project cards (`_data/deck.yml` and `_includes/deck.svg`) are generated, not
hand-edited. The "Refresh project cards" workflow regenerates them daily and
opens a pull request with any change; a repo whose card art has not been uploaded to
Cloudinary yet shows placeholder art and a warning in that run's summary.

## 🔍 Deploys and PR previews

`main` is built by `deploy.yml` and published to the root of the `gh-pages` branch,
which GitHub Pages serves. Every pull request is built under `/pr-preview/pr-<N>/`
by `preview.yml` (noindexed, with the link posted on the PR) and removed again when
the PR closes. Preview builds run the E2E suite against the deployed preview, and
`E2E_BASE_URL=<url> npx playwright test` points it at any deployed copy.

To build a preview locally: `BASEURL=/pr-preview/pr-1 bundle exec rake build:preview`.

## 🧙‍♂️ Features

- Project cards generated from my GitHub repositories (language colors become mana, stars and forks become power and toughness)
- Cards dealt and flipped as they scroll into view, with reduced-motion support
- Responsive layout, with a dark-mode 404 page
- Unit tests, Playwright E2E tests and per-PR previews

## 🛠️ Tech Stack

- Jekyll
- SCSS
- JavaScript
- Font Awesome
- [MTG Card Maker](https://github.com/joe-sharp/mtg_card_maker) for the cards
- Playwright

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
