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

task default: :test
