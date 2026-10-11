# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'
require_relative 'github_project_cards'
require_relative 'deck_sprite'

# Rebuilds the deck YAML and the card sprite from a GitHub user's repositories.
#
# Everything is generated in a temp directory and only copied over the real files
# once every step has succeeded, so a failed fetch or card never leaves a
# half-written deck behind. `runner` receives argument vectors (no shell).
class DeckGenerator
  class Error < StandardError; end

  Result = Struct.new(:cards, :missing_art, keyword_init: true)

  def self.default_runner
    ->(*argv) { system(*argv, exception: true) }
  end

  def initialize(username:, fetcher:, art_checker:, deck_file:, sprite_file:, cards_per_row: 5,
                 runner: self.class.default_runner, out: $stdout)
    @username = username
    @fetcher = fetcher
    @art_checker = art_checker
    @deck_file = deck_file
    @sprite_file = sprite_file
    @cards_per_row = cards_per_row
    @runner = runner
    @out = out
  end

  def call
    cards = GithubProjectCards.fetch(username: @username, fetcher: @fetcher)
    raise Error, "No projects returned for #{@username}; leaving the deck untouched" if cards.empty?

    Dir.mktmpdir('deck') do |dir|
      deck = File.join(dir, 'deck.yml')
      sprite = File.join(dir, 'deck.svg')

      missing = add_cards(cards, deck)
      build_sprite(deck, sprite)
      install(deck, sprite)

      Result.new(cards: cards, missing_art: missing)
    end
  end

  private

  def add_cards(cards, deck)
    cards.each_with_object([]) do |card, missing|
      art = card.art_url
      unless @art_checker.call(art)
        name = card.to_add_card_args[:name]
        @out.puts "::warning title=Missing card art::No card art for #{name} (#{art}); using the placeholder"
        missing << name
        art = GithubProjectCard::PLACEHOLDER_ART_URL
      end

      @out.puts "Adding #{card.to_add_card_args[:name]}"
      @runner.call(*card.to_add_card_argv(deck: deck, art: art))
    end
  end

  def build_sprite(deck, sprite)
    @out.puts 'Regenerating sprite'
    @runner.call('mtg_card_maker', 'generate_sprite', deck, sprite, "--cards-per-row=#{@cards_per_row}")
    File.write(sprite, DeckSprite.prepare(File.read(sprite)))
  end

  def install(deck, sprite)
    FileUtils.mkdir_p([File.dirname(@deck_file), File.dirname(@sprite_file)])
    FileUtils.cp(deck, @deck_file)
    FileUtils.cp(sprite, @sprite_file)
  end
end
