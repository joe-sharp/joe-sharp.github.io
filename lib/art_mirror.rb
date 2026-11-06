# frozen_string_literal: true

require 'fileutils'
require 'net/http'
require_relative 'github_project_card'

# Keeps a WebP copy of each card's art in the site, so the page can show it when
# Cloudinary cannot. Copies that already exist are never downloaded again, so each
# image costs Cloudinary bandwidth once.
class ArtMirror
  class Error < StandardError; end

  def initialize(dir:, get: nil, out: $stdout)
    @dir = dir
    @get = get || method(:net_http_get)
    @out = out
  end

  # Downloads any missing copies and returns the ids that could not be fetched.
  def call(urls)
    FileUtils.mkdir_p(@dir)

    urls.each_with_object([]) do |url, failed|
      id = GithubProjectCard.art_id(url)
      path = File.join(@dir, "#{id}.webp")
      next if File.exist?(path)

      begin
        File.binwrite(path, @get.call(URI(url)))
        @out.puts "Mirrored #{id}"
      rescue StandardError => e
        @out.puts "::warning title=Art mirror failed::#{id}: #{e.message}"
        failed << id
      end
    end
  end

  private

  # Asks for WebP explicitly, so f_auto returns the same format the browser would get.
  def net_http_get(uri)
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'image/webp'

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                                   open_timeout: 15, read_timeout: 30) do |http|
      http.request(request)
    end
    raise Error, "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    response.body
  end
end
