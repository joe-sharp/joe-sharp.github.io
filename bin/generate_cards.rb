#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'
require_relative '../lib/github_project_cards'
require_relative '../lib/deck_sprite'

FETCH_ENDPOINT = 'https://github-project-fetch.vercel.app/api/projects'
DECK_FILE = '_data/deck.yml'
SPRITE_FILE = '_includes/deck.svg'
CARDS_PER_ROW = 5

def endpoint_fetcher
  lambda do |username:|
    uri = URI(FETCH_ENDPOINT)
    uri.query = URI.encode_www_form(username: username)

    response = Net::HTTP.get_response(uri)
    raise "Fetch error #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end
end

def generate_sprite
  puts 'Regenerating Sprite:'
  system("mtg_card_maker generate_sprite #{DECK_FILE} #{SPRITE_FILE} --cards-per-row=#{CARDS_PER_ROW}")
  File.write(SPRITE_FILE, DeckSprite.prepare(File.read(SPRITE_FILE)))
end

# Rebuilds the sprite from the existing deck file without fetching anything.
if ARGV.include?('--sprite-only')
  generate_sprite
  exit
end

username = ARGV[0]

if username.nil? || username.empty?
  warn "Usage: #{$PROGRAM_NAME} <github-username> [--run | --sprite-only]"
  exit 1
end

if ARGV.include?('--run')
  puts "Removing old file:"
  system("rm #{DECK_FILE}")
end

cards = GithubProjectCards.fetch(username: username, fetcher: endpoint_fetcher)

cards.each do |card|
  command = card.to_add_card_command(deck: DECK_FILE)

  if ARGV.include?('--run')
    puts "Running: #{command}"
    system(command)
  else
    puts command
  end
end

if ARGV.include?('--run')
  generate_sprite
end
