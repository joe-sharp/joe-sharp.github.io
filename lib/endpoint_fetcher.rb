# frozen_string_literal: true

require 'json'
require 'net/http'

# Fetches a user's projects from the github_project_fetch endpoint. The endpoint
# is serverless and can be slow on a cold start, so it gets timeouts and retries.
class EndpointFetcher
  ENDPOINT = 'https://github-project-fetch.vercel.app/api/projects'

  class Error < StandardError; end

  def initialize(endpoint: ENDPOINT, attempts: 3, timeout: 30, backoff: 2, http_get: nil, sleeper: Kernel.method(:sleep))
    @endpoint = endpoint
    @attempts = attempts
    @timeout = timeout
    @backoff = backoff
    @http_get = http_get || method(:net_http_get)
    @sleeper = sleeper
  end

  def call(username:)
    uri = URI(@endpoint)
    uri.query = URI.encode_www_form(username: username)

    with_retries { parse(@http_get.call(uri)) }
  end

  private

  def parse(response)
    raise Error, "Fetch error #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def with_retries
    tries = 0
    begin
      tries += 1
      yield
    rescue Error, JSON::ParserError, SystemCallError, Timeout::Error, SocketError => e
      raise if tries >= @attempts

      warn "Fetch attempt #{tries}/#{@attempts} failed (#{e.class}: #{e.message}); retrying"
      @sleeper.call(@backoff**tries)
      retry
    end
  end

  def net_http_get(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                        open_timeout: @timeout, read_timeout: @timeout) do |http|
      http.get(uri.request_uri)
    end
  end
end
