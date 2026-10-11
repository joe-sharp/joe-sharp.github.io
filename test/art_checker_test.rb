# frozen_string_literal: true

require 'test_helper'
require 'art_checker'

describe ArtChecker do
  def checker(result)
    head = ->(_uri) { result.is_a?(Exception) ? raise(result) : result }
    ArtChecker.new(head: head)
  end

  def response(klass, code)
    klass.new('1.1', code, '')
  end

  it 'is true when the image exists' do
    _(checker(response(Net::HTTPOK, '200')).call('https://example.com/a.jpg')).must_equal true
  end

  it 'is false for 404 and 410' do
    _(checker(response(Net::HTTPNotFound, '404')).call('https://example.com/a.jpg')).must_equal false
    _(checker(response(Net::HTTPGone, '410')).call('https://example.com/a.jpg')).must_equal false
  end

  it 'does not call an image missing because of a transient failure' do
    _(checker(Errno::ECONNRESET.new).call('https://example.com/a.jpg')).must_equal true
    _(checker(response(Net::HTTPServiceUnavailable, '503')).call('https://example.com/a.jpg')).must_equal true
  end
end
