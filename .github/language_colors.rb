#!/usr/bin/env ruby
# frozen_string_literal: true

# Syncs Linguist's languages.yml and maps every programming/markup language
# to one of five colors. Each color is derived from a hash of the language
# name, so it never changes between runs; PRESETS override the derived color.
#
# Usage: ruby language_colors.rb [--force]

require "digest"
require "net/http"
require "optparse"
require "yaml"

SOURCE_URL  = "https://raw.githubusercontent.com/github-linguist/linguist/main/lib/linguist/languages.yml"
LOCAL_FILE  = "languages.yml"
OUTPUT_FILE = "language_colors.yml"
COLORS      = %w[black white green red blue].freeze
TYPES       = %w[programming markup].freeze

PRESETS = {
  "ruby"       => "red",
  "rust"       => "red",
  "javascript" => "blue",
  "typescript" => "blue",
  "nodejs"     => "blue",
  "python"     => "green",
  "php"        => "black",
  "shell"      => "white"
}.freeze

options = { force: false }
OptionParser.new do |o|
  o.on("--force", "Regenerate even if languages.yml is unchanged") { options[:force] = true }
end.parse!

def fetch(url)
  res = Net::HTTP.get_response(URI(url))
  abort "Failed to fetch #{url}: #{res.code} #{res.message}" unless res.is_a?(Net::HTTPSuccess)
  res.body
end

# Stable color for a name. Uses SHA-256 rather than String#hash, which is
# randomized per Ruby process.
def color_for(name)
  COLORS[Digest::SHA256.hexdigest(name.downcase).to_i(16) % COLORS.size]
end

# Resolve a preset key to a Linguist language name: exact name, then alias,
# then interpreter (e.g. "nodejs" is an interpreter of JavaScript).
def resolve(key, languages)
  k = key.downcase
  languages.find { |name, _| name.downcase == k }&.first ||
    languages.find { |_, d| Array(d["aliases"]).map(&:downcase).include?(k) }&.first ||
    languages.find { |_, d| Array(d["interpreters"]).map(&:downcase).include?(k) }&.first
end

remote = fetch(SOURCE_URL)
remote_sha = Digest::SHA256.hexdigest(remote)
local_sha = File.exist?(LOCAL_FILE) ? Digest::SHA256.file(LOCAL_FILE).hexdigest : nil

if remote_sha == local_sha && File.exist?(OUTPUT_FILE) && !options[:force]
  puts "languages.yml unchanged (sha256 #{remote_sha[0, 12]}); nothing to do."
  exit
end

if remote_sha == local_sha
  puts "languages.yml unchanged; regenerating #{OUTPUT_FILE}."
else
  File.write(LOCAL_FILE, remote)
  puts "Updated #{LOCAL_FILE} (sha256 #{local_sha&.slice(0, 12) || 'none'} -> #{remote_sha[0, 12]})."
end

languages = YAML.safe_load(remote).select { |_, d| TYPES.include?(d["type"]) }

mapping = languages.keys.to_h { |name| [name, color_for(name)] }

overrides = {}
PRESETS.each do |key, color|
  name = resolve(key, languages)
  if name.nil?
    warn "Skipping preset '#{key}': not a programming/markup language in languages.yml"
  elsif overrides.key?(name) && overrides[name] != color
    warn "Conflict: '#{key}' resolves to #{name}, already #{overrides[name]}; keeping it"
  else
    warn "Preset '#{key}' resolved to '#{name}'" unless name.downcase == key
    overrides[name] = color
  end
end
mapping.merge!(overrides)

sorted = mapping.sort_by { |name, _| name.downcase }.to_h
header = "# Generated from Linguist languages.yml (sha256 #{remote_sha}).\n" \
         "# #{sorted.size} programming/markup languages.\n"
File.write(OUTPUT_FILE, header + sorted.to_yaml.sub(/\A---\n/, ""))
puts "Wrote #{sorted.size} languages to #{OUTPUT_FILE}."
