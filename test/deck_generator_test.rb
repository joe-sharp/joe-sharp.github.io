# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "stringio"
require "deck_generator"

describe DeckGenerator do
  include FixtureHelper

  let(:sprite_svg) do
    <<~SVG
      <?xml version="1.0"?>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 660 910" width="660" height="910">
        <g transform="translate(0, 0)">
        </g>
      </svg>
    SVG
  end

  # Stands in for mtg_card_maker: records argv and writes the files it would.
  let(:runner_class) do
    Class.new do
      attr_reader :calls

      def initialize(sprite_svg)
        @sprite_svg = sprite_svg
        @calls = []
      end

      def call(*argv)
        @calls << argv
        case argv[1]
        when "add_card" then File.write(argv[2], "#{argv[3]}\n", mode: "a")
        when "generate_sprite" then File.write(argv[3], @sprite_svg)
        end
      end

      def add_card_calls
        @calls.select { |argv| argv[1] == "add_card" }
      end
    end
  end

  let(:dir) { Dir.mktmpdir }
  let(:deck_file) { File.join(dir, "data", "deck.yml") }
  let(:sprite_file) { File.join(dir, "includes", "deck.svg") }
  let(:runner) { runner_class.new(sprite_svg) }
  let(:out) { StringIO.new }
  let(:art_checker) { ->(_url) { true } }
  let(:payload) { { "projects" => fixture_projects.first(3) } }
  let(:fetcher) { ->(username:) { payload.tap { @username = username } } }

  after { FileUtils.remove_entry(dir) }

  def generator(**overrides)
    DeckGenerator.new(
      username: "joe-sharp",
      fetcher: fetcher,
      art_checker: art_checker,
      deck_file: deck_file,
      sprite_file: sprite_file,
      runner: runner,
      out: out,
      **overrides
    )
  end

  it "adds one card per project, then writes the deck and a prepared sprite" do
    result = generator.call

    _(result.cards.size).must_equal 3
    _(runner.add_card_calls.size).must_equal 3
    _(File.read(deck_file).lines.size).must_equal 3
    _(File.read(sprite_file)).must_include 'id="deck-card-0"'
    _(runner.calls.last).must_include "--cards-per-row=5"
  end

  it "writes the card links alongside the deck when given a path, empty without forks" do
    links_file = File.join(dir, "data", "card_links.yml")

    generator(card_links_file: links_file).call

    _(YAML.load_file(links_file)).must_equal({})
  end

  it "builds into a temp deck so the real deck is not appended to" do
    FileUtils.mkdir_p(File.dirname(deck_file))
    File.write(deck_file, "stale\n")

    generator.call

    _(File.read(deck_file)).wont_include "stale"
    _(runner.add_card_calls.map { |argv| argv[2] }.uniq).wont_include deck_file
  end

  it "passes hostile descriptions as single argv entries, never through a shell" do
    hostile = '"; touch /tmp/pwned; echo "$(id) `id` -rf'
    payload["projects"] = [fixture_projects.first.merge("description" => hostile)]

    generator.call

    argv = runner.add_card_calls.first
    _(argv).must_include "--rules-text=#{hostile}"
    _(argv.first).must_equal "mtg_card_maker"
  end

  it "leaves existing files untouched when nothing is returned" do
    FileUtils.mkdir_p([File.dirname(deck_file), File.dirname(sprite_file)])
    File.write(deck_file, "old deck")
    File.write(sprite_file, "old sprite")
    payload["projects"] = []

    _(-> { generator.call }).must_raise DeckGenerator::Error

    _(File.read(deck_file)).must_equal "old deck"
    _(File.read(sprite_file)).must_equal "old sprite"
    _(runner.calls).must_be_empty
  end

  it "leaves existing files untouched when a step fails part way" do
    FileUtils.mkdir_p([File.dirname(deck_file), File.dirname(sprite_file)])
    File.write(deck_file, "old deck")
    File.write(sprite_file, "old sprite")
    failing = lambda do |*argv|
      raise "boom" if argv[1] == "generate_sprite"

      runner.call(*argv)
    end

    _(-> { generator(runner: failing).call }).must_raise RuntimeError

    _(File.read(deck_file)).must_equal "old deck"
    _(File.read(sprite_file)).must_equal "old sprite"
  end

  describe "when a repo has no art yet" do
    # The first card in the deck, so the placeholder is the one that gets checked first.
    let(:missing_name) { GithubProjectCards.sort_by_updated(payload["projects"]).first["name"] }
    let(:art_checker) { ->(url) { !url.include?(Digest::MD5.hexdigest(missing_name)) } }

    it "hands the art it used to the mirror, including the placeholder" do
      mirrored = []

      generator(art_mirror: ->(urls) { mirrored.concat(urls) }).call

      _(mirrored).must_include GithubProjectCard::PLACEHOLDER_ART_URL
      _(mirrored).wont_include GithubProjectCard.new(fixture_project(missing_name)).art_url
    end

    it "uses the placeholder art, reports it, and still builds the deck" do
      result = generator.call

      _(result.missing_art).must_equal [missing_name]
      _(runner.add_card_calls.first).must_include "--art=#{GithubProjectCard::PLACEHOLDER_ART_URL}"
      _(runner.add_card_calls[1..].flatten.grep(/\A--art=/)).wont_include "--art=#{GithubProjectCard::PLACEHOLDER_ART_URL}"
      _(out.string).must_include "::warning title=Missing card art::No card art for #{missing_name}"
    end
  end
end
