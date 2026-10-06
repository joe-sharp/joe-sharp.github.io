# frozen_string_literal: true

require 'test_helper'
require 'deck_sprite'

describe DeckSprite do
  let(:sprite) do
    <<~SVG
      <?xml version="1.0"?>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1320 910" width="1320" height="910">
        <defs>
          <style type="text/css"></style>
        </defs>
        <g transform="translate(0, 0)">
      <g transform="translate(470, 63)">
      </g>
      </g>
        <g transform="translate(660, 0)">
      </g>
      </svg>
    SVG
  end

  let(:prepared) { DeckSprite.prepare(sprite) }

  it 'gives each top-level card group a sequential id, leaving nested groups alone' do
    _(prepared).must_include '<g id="deck-card-0" transform="translate(0, 0)">'
    _(prepared).must_include '<g id="deck-card-1" transform="translate(660, 0)">'
    _(prepared).must_include '<g transform="translate(470, 63)">'
    _(prepared.scan('id="deck-card-').size).must_equal 2
  end

  it 'makes the root zero-size and keeps its viewBox' do
    _(prepared).must_include 'viewBox="0 0 1320 910" width="0" height="0" aria-hidden="true"'
  end

  it 'wraps the cards in <defs> so they are only drawn through <use>' do
    _(prepared).must_match(%r{</defs>\n<defs>\n  <g id="deck-card-0"})
    _(prepared).must_match(%r{</defs>\n</svg>\n\z})
  end

  it 'is idempotent' do
    _(DeckSprite.prepare(prepared)).must_equal prepared
  end
end
