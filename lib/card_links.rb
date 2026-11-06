# frozen_string_literal: true

# Works out where each fork card's rules-text links go, as percentages of the
# card, so the site can draw clickable boxes over the printed lines. The
# positions come from the sprite, which is where the text was actually laid out.
module CardLinks
  CARD_HEIGHT = 880.0

  # Rules lines are 24px text on a 26.5px grid. A box starts a little above the baseline.
  LINE_HEIGHT = 26.5
  BASELINE_OFFSET = 21

  RULES_LINE = /<text x="[\d.]+" y="([\d.]+)"[^>]*class="card-rules-text"/

  module_function

  # Returns { card name => [{ 'href', 'label', 'top', 'height' }] } for the forks with links.
  def build(sprite, cards)
    baselines = rules_baselines(sprite)

    cards.each_with_index.with_object({}) do |(card, index), links|
      next unless card.fork?

      boxes = boxes_for(card.rules_links, baselines.fetch(index, []))
      links[card.attributes['name']] = boxes unless boxes.empty?
    end
  end

  # The baseline of every rules line, by card index, read from the sprite.
  def rules_baselines(sprite)
    sprite.scan(/<g id="deck-card-(\d+)"(.*?)(?=<g id="deck-card-|\z)/m).to_h do |index, body|
      [index.to_i, body.scan(RULES_LINE).flatten.map(&:to_f)]
    end
  end

  # One box per line when there is a link per line (a list). Otherwise one box
  # covering every rules line (a summary).
  def boxes_for(links, baselines)
    return [] if links.empty? || baselines.empty?

    if links.size == baselines.size
      links.zip(baselines).map { |link, baseline| box(link, baseline, LINE_HEIGHT) }
    else
      height = baselines.last - baselines.first + LINE_HEIGHT
      [box(links.first, baselines.first, height)]
    end
  end

  def box(link, baseline, height)
    {
      'href' => link['href'],
      'label' => link['label'],
      'top' => percent(baseline - BASELINE_OFFSET, CARD_HEIGHT),
      'height' => percent(height, CARD_HEIGHT)
    }
  end

  def percent(value, total)
    (value / total * 100).round(3)
  end
end
