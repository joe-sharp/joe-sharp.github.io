# frozen_string_literal: true

require "digest"
require "yaml"

# A single GitHub project, prepared for rendering as a card
class GithubProjectCard
  LANGUAGE_COLORS_FILE = File.join(__dir__, "../language_colors.yml")
  # These flags are only added when they have a value
  OPTIONAL_FLAGS = %w[mana-cost power toughness].freeze

  # Maps color name -> mana symbol short code
  COLOR_MANA_CODE = {
    "blue" => "U",
    "black" => "B",
    "white" => "W",
    "red" => "R",
    "green" => "G"
  }.freeze

  MULTICOLOR_THRESHOLD = 0.15

  # Non-fork repos are gold once stars + forks reach this, otherwise silver.
  GOLD_POPULARITY = 10

  # Forks never get silver or gold. White is recolored to black for light pages
  # by the --fork-frame CSS variable (see DeckSprite).
  FORK_BORDER_COLOR = "white"

  # Forks with more PRs into the parent than this get a one-line summary instead of a list.
  MAX_LISTED_PRS = 5

  # Rules text wraps at about 51 characters per line on the card, so each listed PR fits on one line.
  RULES_LINE_CHARS = 50

  PR_STATUS_SYMBOLS = { "merged" => "✓", "open" => "●" }.freeze

  # Type line shows only the top languages; when it is truncated, each color
  # is capped at MAX_PIPS_PER_COLOR pips and every skipped pip adds 1 generic mana.
  MAX_TYPE_LINE_LANGUAGES = 5
  MAX_PIPS_PER_COLOR = 2

  ART_BASE_URL = "https://res.cloudinary.com/uv7kncpy/image/upload"

  # Card art is shown in a 550x400 slot, so it is delivered at 660x480 (a 1.2x
  # margin) and cropped the same way the SVG's preserveAspectRatio crops it.
  ART_TRANSFORMATION = "f_auto,q_auto,c_fill,g_center,w_660,h_480"

  # Shown for a repo whose art has not been uploaded to Cloudinary yet.
  PLACEHOLDER_ART_URL = "#{ART_BASE_URL}/#{ART_TRANSFORMATION}/v1790537119/c21f969b5f03d33d43e04f8f136e7682.jpg".freeze

  attr_reader :attributes

  def initialize(attributes)
    @attributes = attributes
  end

  def to_add_card_args(art: nil)
    {
      name: name,
      art: art || art_url,
      mana_cost: mana_cost,
      type_line: type_line,
      rules_text: rules_text,
      flavor_text: flavor_text,
      border_color: border_color,
      power: power,
      toughness: toughness,
      color: color
    }
  end

  # Human-readable (dry-run) form. Never hand this to a shell: values come from
  # third-party repo descriptions. Use #to_add_card_argv to actually run it.
  def to_add_card_command(deck: "deck.yml")
    flags = add_card_flags.map { |flag, value| %(--#{flag}="#{value}") }

    "mtg_card_maker add_card #{deck} #{flags.join(" ")}"
  end

  # Argument vector for `mtg_card_maker add_card`, safe to pass to Kernel#system
  # with no shell involved.
  def to_add_card_argv(deck: "deck.yml", art: nil)
    flags = add_card_flags(art: art).map { |flag, value| "--#{flag}=#{value}" }

    ["mtg_card_maker", "add_card", deck, *flags]
  end

  # The untransformed original. Checking this does not create derived images.
  # Links drawn over the rules text of a fork card, as [{ "href", "label" }] hashes.
  def rules_links
    return [] unless pull_request_text?

    if pull_requests_total > MAX_LISTED_PRS
      [{ "href" => pull_requests_search_url, "label" => pull_request_summary_text }]
    else
      pull_requests.map { |pr| { "href" => pr["html_url"], "label" => pr["title"] } }
    end
  end

  def fork?
    attributes["fork"] == true
  end

  def art_source_url
    "#{ART_BASE_URL}/#{Digest::MD5.hexdigest(name)}.jpg"
  end

  # The Cloudinary URL this repo's card art is expected to live at, resized for the card.
  def art_url
    "#{ART_BASE_URL}/#{ART_TRANSFORMATION}/#{Digest::MD5.hexdigest(name)}.jpg"
  end

  # The 32-character id at the end of a Cloudinary art URL. It is also the file
  # name of that art's copy in images/art/.
  def self.art_id(url)
    url[%r{/(\h{32})\.jpg\z}, 1]
  end

  def self.language_color_map
    @language_color_map ||= YAML.load_file(LANGUAGE_COLORS_FILE)
  end

  private

  def name
    attributes["name"]
  end

  def add_card_flags(art: nil)
    args = to_add_card_args(art: art)
    flags = [
      ["name", args[:name]],
      ["art", args[:art]],
      ["mana-cost", args[:mana_cost]],
      ["type-line", args[:type_line]],
      ["color", args[:color]],
      ["border-color", args[:border_color]],
      ["power", args[:power]],
      ["toughness", args[:toughness]],
      ["rules-text", cli_text(args[:rules_text])],
      ["flavor-text", cli_text(args[:flavor_text])]
    ]
    present = flags.reject { |flag, value| OPTIONAL_FLAGS.include?(flag) && !value }
    present.reject { |flag, value| flag == "rules-text" && value.empty? }
  end

  # The mtg_card_maker CLI only keeps the first line of a multi-line argument, and
  # it turns a literal backslash-n back into a newline, so newlines are sent that way.
  def cli_text(text)
    text&.gsub("\n") { '\\n' }
  end

  def languages
    attributes["languages"] || {}
  end

  def languages_by_usage
    languages.sort_by { |_lang, bytes| -bytes }
  end

  def total_bytes
    languages.values.sum
  end

  def top_language_bytes
    languages_by_usage.first&.last
  end

  # Loads and memoizes the Language => color-name map from language_colors.yml
  def language_color_map
    self.class.language_color_map
  end

  # Looks up a language's color name via language_colors.yml, then converts
  # that color name to its mana symbol short code via COLOR_MANA_CODE.
  def language_mana_code(lang)
    color_name = language_color_map[lang]
    return nil unless color_name

    COLOR_MANA_CODE[color_name]
  end

  def mana_cost
    return nil if languages.empty?

    generic = (Math.log10(top_language_bytes) - 1).round
    groups = languages_by_usage
      .filter_map { |lang, _bytes| language_mana_code(lang) }
      .group_by(&:itself)
      .values

    if type_line_truncated?
      skipped = groups.sum { |group| [group.size - MAX_PIPS_PER_COLOR, 0].max }
      generic += skipped
      groups = groups.map { |group| group.first(MAX_PIPS_PER_COLOR) }
    end

    "#{generic}#{groups.join}"
  end

  def type_line_truncated?
    languages.size > MAX_TYPE_LINE_LANGUAGES
  end

  def type_line
    languages_by_usage.first(MAX_TYPE_LINE_LANGUAGES).map(&:first).join(", ")
  end

  def rules_text
    return attributes["description"] || "" unless pull_request_text?

    (pull_requests_total > MAX_LISTED_PRS) ? pull_request_summary_text : pull_request_list_text
  end

  def pull_request_text?
    fork? && pull_requests_total.positive?
  end

  # Closed PRs are left off the card: they are not listed, linked, or counted.
  def pull_requests
    (attributes["pull_requests"] || []).reject { |pr| pr["state"] == "closed" }
  end

  def pull_requests_total
    total = attributes["pull_requests_total"] || pull_requests.size
    total - (attributes["pull_requests"] || []).count { |pr| pr["state"] == "closed" }
  end

  def pull_request_list_text
    pull_requests.map do |pr|
      symbol = PR_STATUS_SYMBOLS.fetch(pr["state"], "?")
      pull_request_line("#{symbol}: #{pr["title"]}")
    end.join("\n")
  end

  # Braces would render as HTML in the sprite, so they become parentheses.
  def pull_request_line(text)
    text = text.tr("{}", "()")
    return text if text.length <= RULES_LINE_CHARS

    "#{text[0, RULES_LINE_CHARS - 1]}…"
  end

  def pull_request_summary_text
    counts = pull_requests.map { |pr| pr["state"] }.tally
    parts = %w[merged open].filter_map { |state| "#{counts[state]} #{state}" if counts[state].to_i.positive? }

    "#{pull_requests_total} PRs to #{attributes["parent_full_name"]}: #{parts.join(", ")}"
  end

  def pull_requests_search_url
    owner = attributes["html_url"][%r{github\.com/([^/]+)/}, 1]
    "https://github.com/#{attributes["parent_full_name"]}/pulls?q=is%3Apr+author%3A#{owner}"
  end

  def parent_full_name
    attributes["parent_full_name"]
  end

  def fork_of_known_parent?
    fork? && !parent_full_name.to_s.empty?
  end

  def flavor_text
    url = attributes["html_url"]
    return "#{url}\n#{name}, forked from #{parent_full_name}" if fork_of_known_parent?

    created_date = attributes["created_at"].to_s.split.first

    "#{url}\nCreated: #{created_date}"
  end

  def border_color
    return FORK_BORDER_COLOR if fork?

    popularity = attributes["stargazers_count"].to_i + attributes["forks_count"].to_i
    (popularity >= GOLD_POPULARITY) ? "gold" : "silver"
  end

  def power
    return nil if creature_stats_empty?

    attributes["stargazers_count"].to_i
  end

  def toughness
    return nil if creature_stats_empty?

    attributes["forks_count"].to_i
  end

  def creature_stats_empty?
    attributes["stargazers_count"].to_i.zero? && attributes["forks_count"].to_i.zero?
  end

  def color
    return "colorless" if languages.empty?

    multicolor = languages_by_usage.count { |_lang, bytes| bytes.to_f / total_bytes >= MULTICOLOR_THRESHOLD } >= 2
    return "gold" if multicolor

    top_language = languages_by_usage.first.first
    language_color_map[top_language] || "colorless"
  end
end
