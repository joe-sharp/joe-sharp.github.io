# frozen_string_literal: true

source 'https://rubygems.org'

# This is the default theme for new Jekyll sites. You may change this to anything you like.
gem 'minima', '~> 2.0'

# If you want to use GitHub Pages, remove the "gem "jekyll"" above and
# uncomment the line below. To upgrade, run `bundle update github-pages`.
gem 'github-pages', group: :jekyll_plugins

# If you have any plugins, put them here!
group :jekyll_plugins do
  gem 'jekyll-feed', '~> 0.6'
  gem 'jekyll-seo-tag'
  gem 'jekyll-theme-primer'
end

# Lock `http_parser.rb` gem to `v0.6.x` on JRuby builds since newer versions of the gem
# do not have a Java counterpart.
gem 'http_parser.rb', '~> 0.6', platforms: [:jruby]

gem 'mtg_card_maker', '~> 0.1.0'

group :test do
  gem 'minitest', '~> 5.25'
  gem 'rake', '~> 13.2'
end

gem 'cloudinary', '~> 2.4'

gem 'dotenv', '~> 3.2'

gem 'debug', '~> 1.11', require: 'debug'
