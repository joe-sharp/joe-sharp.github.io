#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/github_project_cards'
require_relative '../lib/deck_sprite'
require_relative '../lib/deck_generator'
require_relative '../lib/endpoint_fetcher'
require_relative '../lib/art_checker'

DECK_FILE = '_data/deck.yml'
SPRITE_FILE = '_includes/deck.svg'
CARDS_PER_ROW = 5

USAGE = "Usage: #{$PROGRAM_NAME} <github-username> [--run | --sprite-only]".freeze

# Rebuilds the sprite from the existing deck file without fetching anything.
if ARGV.include?('--sprite-only')
  puts 'Regenerating Sprite:'
  system('mtg_card_maker', 'generate_sprite', DECK_FILE, SPRITE_FILE, "--cards-per-row=#{CARDS_PER_ROW}",
         exception: true)
  File.write(SPRITE_FILE, DeckSprite.prepare(File.read(SPRITE_FILE)))
  exit
end

username = ARGV.reject { |arg| arg.start_with?('--') }.first

if username.nil? || username.empty?
  warn USAGE
  exit 1
end

if ARGV.include?('--run')
  begin
    result = DeckGenerator.new(
      username: username, fetcher: EndpointFetcher.new, art_checker: ArtChecker.new,
      deck_file: DECK_FILE, sprite_file: SPRITE_FILE, cards_per_row: CARDS_PER_ROW
    ).call
  rescue DeckGenerator::Error, EndpointFetcher::Error => e
    warn e.message
    exit 1
  end

  puts "Wrote #{result.cards.size} cards to #{DECK_FILE} and #{SPRITE_FILE}"

  # Surface repos still waiting on art in the Actions job summary.
  if (summary = ENV['GITHUB_STEP_SUMMARY']) && result.missing_art.any?
    File.open(summary, 'a') do |f|
      f.puts '### Cards using placeholder art'
      result.missing_art.each { |name| f.puts "- #{name}" }
    end
  end
else
  # Dry run: print what would be run, change nothing.
  GithubProjectCards.fetch(username: username, fetcher: EndpointFetcher.new).each do |card|
    puts card.to_add_card_command(deck: DECK_FILE)
  end
end
