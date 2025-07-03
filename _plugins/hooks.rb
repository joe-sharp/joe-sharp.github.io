require 'fileutils'
require 'json'

Jekyll::Hooks.register :site, :pre_render do |site, _payload|
  site.pages.each do |page|
    page.data['rel_dir'] = File.dirname(page.path)
    page.data['basename'] = File.basename(page.path)
    page.data['filename'] = File.basename(page.path, '.*')
  end
  site.posts.docs.each do |post|
    post.data['rel_dir'] = File.dirname(post.path)
    post.data['basename'] = File.basename(post.path)
    post.data['filename'] = File.basename(post.path, '.*')
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  cache_dir = File.join(site.source, '.jekyll-cache', 'github-metadata')
  cache_file = File.join(cache_dir, 'repo_data.json')

  if File.exist?(cache_file)
    begin
      cached_data = JSON.parse(File.read(cache_file))
      site.config['github'] = cached_data
      Jekyll.logger.info 'GitHub Metadata:', "Using cached data from #{cache_file}"
    rescue JSON::ParserError => e
      Jekyll.logger.error 'GitHub Metadata:', "Cache file parse error: #{e.message}"
    end
  else
    Jekyll.logger.warn 'GitHub Metadata:', "No cache file found at #{cache_file}"
  end
end
