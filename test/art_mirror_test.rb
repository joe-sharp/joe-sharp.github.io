# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'stringio'
require 'art_mirror'

describe ArtMirror do
  let(:dir) { Dir.mktmpdir }
  let(:out) { StringIO.new }
  let(:id) { 'faa79416b855ca1c82b6b5aeb3c3235a' }
  let(:url) { "https://res.cloudinary.com/uv7kncpy/image/upload/f_auto,w_660/#{id}.jpg" }
  let(:fetched) { [] }
  let(:get) do
    lambda do |uri|
      fetched << uri.to_s
      'WEBP'
    end
  end

  after { FileUtils.remove_entry(dir) }

  def mirror
    ArtMirror.new(dir: dir, get: get, out: out)
  end

  it 'saves each art as a WebP named by its id' do
    _(mirror.call([url])).must_be_empty

    _(File.binread(File.join(dir, "#{id}.webp"))).must_equal 'WEBP'
    _(fetched).must_equal [url]
  end

  it 'never downloads a copy that already exists' do
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "#{id}.webp"), 'OLD')

    mirror.call([url])

    _(fetched).must_be_empty
    _(File.read(File.join(dir, "#{id}.webp"))).must_equal 'OLD'
  end

  it 'reports a failed download as a warning and writes nothing' do
    failing = ->(_uri) { raise SocketError, 'getaddrinfo failed' }

    failed = ArtMirror.new(dir: dir, get: failing, out: out).call([url])

    _(failed).must_equal [id]
    _(out.string).must_include "::warning title=Art mirror failed::#{id}: getaddrinfo failed"
    _(File.exist?(File.join(dir, "#{id}.webp"))).must_equal false
  end
end
