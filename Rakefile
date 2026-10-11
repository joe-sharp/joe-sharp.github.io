# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = true
end

# Builds like GitHub Pages does: production environment, safe mode (no _plugins).
desc 'Build the site into _site the way production does'
task :build do
  ENV['JEKYLL_ENV'] = 'production'
  sh 'bundle exec jekyll build --safe'
end

desc 'Run the Playwright end-to-end tests against a fresh production build'
task e2e: :build do
  sh 'npx playwright test'
end

GITHUB_USERNAME = 'joe-sharp'

desc 'Regenerate _data/deck.yml and _includes/deck.svg from GitHub'
task :deck do
  sh 'ruby', 'bin/generate_cards.rb', GITHUB_USERNAME, '--run'
end

namespace :deck do
  desc 'Rebuild only the sprite from the existing deck file'
  task :sprite do
    sh 'ruby', 'bin/generate_cards.rb', '--sprite-only'
  end
end

task default: :test
