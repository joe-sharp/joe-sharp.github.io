# frozen_string_literal: true

source 'https://rubygems.org'

# This is the default theme for new Jekyll sites. You may change this to anything you like.
gem 'minima', '~> 2.0'

# The site is built in GitHub Actions and deployed to gh-pages, so the
# github-pages meta-gem is not needed. Its jekyll-remote-theme dependency also
# capped rubyzip below 3.0.
gem 'jekyll', '~> 3.10'

# Jekyll 3.x relies on these, which stopped being default gems in Ruby 3.4.
gem 'base64'
gem 'bigdecimal'
gem 'kramdown-parser-gfm'

# If you have any plugins, put them here!
group :jekyll_plugins do
  gem 'jekyll-seo-tag'
  gem 'jekyll-theme-primer'
end

# Lock `http_parser.rb` gem to `v0.6.x` on JRuby builds since newer versions of the gem
# do not have a Java counterpart.
gem 'http_parser.rb', '~> 0.6', platforms: [:jruby]

gem 'mtg_card_maker', '~> 0.2.1'

group :test do
  gem 'minitest', '~> 6.0'
  gem 'rake', '~> 13.2'
end

gem 'cloudinary', '~> 2.4'

gem 'dotenv', '~> 3.2'

gem 'debug', '~> 1.11', require: 'debug'
