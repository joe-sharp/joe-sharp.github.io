# frozen_string_literal: true

require "test_helper"
require "deck_sprite"

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

  it "gives each top-level card group a sequential id, leaving nested groups alone" do
    _(prepared).must_include '<g id="deck-card-0" transform="translate(0, 0)">'
    _(prepared).must_include '<g id="deck-card-1" transform="translate(660, 0)">'
    _(prepared).must_include '<g transform="translate(470, 63)">'
    _(prepared.scan('id="deck-card-').size).must_equal 2
  end

  it "makes the root zero-size and keeps its viewBox" do
    _(prepared).must_include 'viewBox="0 0 1320 910" width="0" height="0" aria-hidden="true"'
  end

  it "wraps the cards in <defs> so they are only drawn through <use>" do
    _(prepared).must_match(%r{</defs>\n<defs>\n  <g id="deck-card-0"})
    _(prepared).must_match(%r{</defs>\n</svg>\n\z})
  end

  it "is idempotent" do
    _(DeckSprite.prepare(prepared)).must_equal prepared
  end

  describe 'fork frames' do
    let(:framed_sprite) do
      <<~SVG
        <?xml version="1.0"?>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1320 910" width="1320" height="910">
          <g transform="translate(0, 0)">
            <rect x="0" y="0" width="630" height="880" fill="#EEE" rx="25" ry="25" mask="url(#artWindowMask)"/>
          </g>
          <g transform="translate(660, 0)">
            <rect x="0" y="0" width="630" height="880" fill="#EEE" rx="25" ry="25" mask="url(#artWindowMask)"/>
          </g>
        </svg>
      SVG
    end

    it 'fills only the listed cards\' frames from the --fork-frame variable' do
      prepared = DeckSprite.prepare(framed_sprite, fork_indices: [1])

      _(prepared.scan('var(--fork-frame, #EEE)').size).must_equal 1
      _(prepared.index('var(--fork-frame')).must_be :>, prepared.index('deck-card-1')
      _(prepared).must_include 'fill="#EEE" rx="25" ry="25"'
    end

    it 'leaves the frames alone when no fork indices are given' do
      _(DeckSprite.prepare(framed_sprite)).wont_include 'var(--fork-frame'
    end
  end
end
