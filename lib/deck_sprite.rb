# frozen_string_literal: true

# Prepares the sprite written by `mtg_card_maker generate_sprite` for inlining in a
# page: every card <g> gets an id (deck-card-N), the cards move into <defs> and the
# root becomes zero-size, so the page can show each card by cropping the sprite
# with a per-card viewBox and <use href="#deck-card-N">.
module DeckSprite
  CARD_GROUP = /^  <g transform="translate\(\d+, \d+\)">/

  def self.prepare(svg)
    return svg if svg.include?('id="deck-card-0"')

    index = -1
    svg = svg.gsub(CARD_GROUP) { |tag| tag.sub('<g ', %(<g id="deck-card-#{index += 1}" )) }
    svg = svg.sub(/(<svg[^>]*?) width="\d+" height="\d+"/, '\1 width="0" height="0" aria-hidden="true"')
    first_card = svg.index(/^  <g id="deck-card-0"/)
    return svg unless first_card

    svg.insert(first_card, "<defs>\n")
    svg.sub(%r{</svg>\s*\z}, "</defs>\n</svg>\n")
  end
end
