#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'
require_relative '../lib/github_project_cards'

FETCH_ENDPOINT = 'https://github-project-fetch.vercel.app/api/projects'

def endpoint_fetcher
  lambda do |username:|
    uri = URI(FETCH_ENDPOINT)
    uri.query = URI.encode_www_form(username: username)

    response = Net::HTTP.get_response(uri)
    raise "Fetch error #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end
end

username = ARGV[0]

if username.nil? || username.empty?
  warn "Usage: #{$PROGRAM_NAME} <github-username> [--run]"
  exit 1
end

if ARGV.include?('--run')
  puts "Removing old file:"
  system("rm deck.yml")
end

cards = GithubProjectCards.fetch(username: username, fetcher: endpoint_fetcher)

cards.each do |card|
  command = card.to_add_card_command

  if ARGV.include?('--run')
    puts "Running: #{command}"
    system(command)
  else
    puts command
  end
end

if ARGV.include?('--run')
  puts "Regenerating Sprite:"
  system("mtg_card_maker generate_sprite deck.yml deck.svg")
end
