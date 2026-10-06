# frozen_string_literal: true

require 'digest'
require 'yaml'

class GithubProjectCard
  LANGUAGE_COLORS_FILE = File.join(__dir__, '../language_colors.yml')

  # Maps color name -> mana symbol short code
  COLOR_MANA_CODE = {
    'blue' => 'U',
    'black' => 'B',
    'white' => 'W',
    'red' => 'R',
    'green' => 'G'
  }.freeze

  MULTICOLOR_THRESHOLD = 0.15

  # Type line shows only the top languages; when it is truncated, each color
  # is capped at MAX_PIPS_PER_COLOR pips and every skipped pip adds 1 generic mana.
  MAX_TYPE_LINE_LANGUAGES = 5
  MAX_PIPS_PER_COLOR = 2

  ART_BASE_URL = 'https://res.cloudinary.com/uv7kncpy/image/upload'

  attr_reader :attributes

  def initialize(attributes)
    @attributes = attributes
  end

  def to_add_card_args
    {
      name: name,
      art: art,
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

  def to_add_card_command(deck: 'deck.yml')
    args = to_add_card_args
    flags = []
    flags << %(--name="#{args[:name]}")
    flags << %(--art="#{args[:art]}")
    flags << %(--mana-cost="#{args[:mana_cost]}") if args[:mana_cost]
    flags << %(--type-line="#{args[:type_line]}")
    flags << %(--color="#{args[:color]}")
    flags << %(--border-color="#{args[:border_color]}")
    flags << %(--power="#{args[:power]}") if args[:power]
    flags << %(--toughness="#{args[:toughness]}") if args[:toughness]
    flags << %(--rules-text="#{args[:rules_text]}")
    flags << %(--flavor-text="#{args[:flavor_text]}")

    "mtg_card_maker add_card #{deck} #{flags.join(' ')}"
  end

  private

  def name
    attributes['name']
  end

  def art
    md5 = Digest::MD5.hexdigest(name)
    "#{ART_BASE_URL}/#{md5}.jpg"
  end

  def languages
    attributes['languages'] || {}
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

  def self.language_color_map
    @language_color_map ||= YAML.load_file(LANGUAGE_COLORS_FILE)
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

    "#{generic}#{groups.flatten.join}"
  end

  def type_line_truncated?
    languages.size > MAX_TYPE_LINE_LANGUAGES
  end

  def type_line
    languages_by_usage.first(MAX_TYPE_LINE_LANGUAGES).map(&:first).join(', ')
  end

  def rules_text
    attributes['description'] || ''
  end

  def flavor_text
    url = attributes['html_url']
    created_date = attributes['created_at'].to_s.split(' ').first

    "#{url}\nCreated: #{created_date}"
  end

  def border_color
    stars = attributes['stargazers_count'].to_i
    return 'white' if stars <= 0

    bucket = Math.log10(stars).round
    case bucket
    when 0, 1 then 'white'
    when 2 then 'black'
    when 3 then 'silver'
    else 'gold'
    end
  end

  def power
    return nil if creature_stats_empty?

    attributes['stargazers_count'].to_i
  end

  def toughness
    return nil if creature_stats_empty?

    attributes['forks_count'].to_i
  end

  def creature_stats_empty?
    attributes['stargazers_count'].to_i.zero? && attributes['forks_count'].to_i.zero?
  end

  def color
    return 'colorless' if languages.empty?

    multicolor = languages_by_usage.count { |_lang, bytes| bytes.to_f / total_bytes >= MULTICOLOR_THRESHOLD } >= 2
    return 'gold' if multicolor

    top_language = languages_by_usage.first.first
    language_color_map[top_language] || 'colorless'
  end
end
