# frozen_string_literal: true

require 'net/http'

# Answers whether a card's art has been uploaded to Cloudinary yet.
class ArtChecker
  MISSING = [Net::HTTPNotFound, Net::HTTPGone].freeze

  def initialize(timeout: 15, head: nil)
    @timeout = timeout
    @head = head || method(:net_http_head)
  end

  # True unless the server says the image does not exist; transient failures are
  # not treated as "missing" so a Cloudinary blip never swaps in placeholder art.
  def call(url)
    response = @head.call(URI(url))
    MISSING.none? { |klass| response.is_a?(klass) }
  rescue SystemCallError, Timeout::Error, SocketError, Net::ProtocolError
    true
  end

  private

  def net_http_head(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                        open_timeout: @timeout, read_timeout: @timeout) do |http|
      http.head(uri.request_uri)
    end
  end
end
