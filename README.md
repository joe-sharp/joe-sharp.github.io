# Joe Sharp's Personal Site ✨

A minimalist Jekyll-powered project display.

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
bundle exec rake deck        # regenerate the project cards from GitHub
bundle exec rake deck:sprite # rebuild only the sprite from _data/deck.yml
```

The project cards (`_data/deck.yml` and `_includes/deck.svg`) are generated, not
hand-edited. The "Refresh project cards" workflow regenerates them daily and
opens a pull request with any change; a repo whose card art has not been uploaded to
Cloudinary yet shows placeholder art and a warning in that run's summary.

## 🧙‍♂️ Features

- Clean, minimalist design
- Responsive layout
- Blog support
- Easy customization

## 🛠️ Tech Stack

- Jekyll
- SCSS
- JavaScript
- Font Awesome

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
