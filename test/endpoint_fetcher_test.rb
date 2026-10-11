# frozen_string_literal: true

require 'test_helper'
require 'endpoint_fetcher'

describe EndpointFetcher do
  def response(klass, body)
    klass.new('1.1', klass == Net::HTTPOK ? '200' : '500', '').tap do |r|
      r.instance_variable_set(:@read, true)
      r.instance_variable_set(:@body, body)
    end
  end

  let(:sleeps) { [] }
  let(:ok) { response(Net::HTTPOK, '{"projects": []}') }
  let(:error) { response(Net::HTTPInternalServerError, 'nope') }

  def fetcher(responses, attempts: 3)
    queue = responses.dup
    seen = []
    http_get = lambda do |uri|
      seen << uri
      item = queue.shift
      raise item if item.is_a?(Class) || item.is_a?(Exception)

      item
    end
    [EndpointFetcher.new(attempts: attempts, http_get: http_get, sleeper: ->(s) { sleeps << s }), seen]
  end

  it 'requests the endpoint with the username and parses the JSON' do
    instance, seen = fetcher([ok])

    _(instance.call(username: 'joe sharp')).must_equal({ 'projects' => [] })
    _(seen.first.to_s).must_equal "#{EndpointFetcher::ENDPOINT}?username=joe+sharp"
  end

  it 'retries failures with backoff and then succeeds' do
    instance, = fetcher([error, Errno::ECONNRESET.new, ok])

    _(capture_io { _(instance.call(username: 'x')).must_equal({ 'projects' => [] }) }.last).must_include 'retrying'
    _(sleeps).must_equal [2, 4]
  end

  it 'raises after exhausting its attempts' do
    instance, = fetcher([error, error], attempts: 2)

    capture_io do
      err = _(-> { instance.call(username: 'x') }).must_raise EndpointFetcher::Error
      _(err.message).must_include 'Fetch error 500'
    end
  end
end
