# frozen_string_literal: true

require "test_helper"
require "github_project_card"

describe GithubProjectCard do
  include FixtureHelper

  def args_for(name, **overrides)
    GithubProjectCard.new(fixture_project(name).merge(overrides.transform_keys(&:to_s))).to_add_card_args
  end

  it "maps color names to mana pips in a constant" do
    _(GithubProjectCard::COLOR_MANA_CODE).must_equal(
      {
        "blue" => "U",
        "black" => "B",
        "white" => "W",
        "red" => "R",
        "green" => "G"
      }
    )
  end

  describe "#to_add_card_args" do
    it "uses the repo name for --name" do
      _(args_for("appraisal")[:name]).must_equal "appraisal"
      _(args_for("joe-sharp.github.io")[:name]).must_equal "joe-sharp.github.io"
    end

    it "uses a resized Cloudinary URL with an MD5 checksum of the repo name as the art" do
      base = "https://res.cloudinary.com/uv7kncpy/image/upload/#{GithubProjectCard::ART_TRANSFORMATION}"
      # Digest::MD5.hexdigest('joe-sharp.github.io')
      _(args_for("joe-sharp.github.io")[:art]).must_equal "#{base}/faa79416b855ca1c82b6b5aeb3c3235a.jpg"
      _(args_for("mtg_card_maker")[:art]).must_equal "#{base}/595f103c608631e0049772bf3ad48b06.jpg"
    end

    it "keeps the untransformed original for the existence check" do
      card = GithubProjectCard.new(fixture_project("joe-sharp.github.io"))

      _(card.art_source_url).must_equal "https://res.cloudinary.com/uv7kncpy/image/upload/faa79416b855ca1c82b6b5aeb3c3235a.jpg"
    end

    it "reads the art id from any Cloudinary art url, with or without a version or transformation" do
      _(GithubProjectCard.art_id(GithubProjectCard::PLACEHOLDER_ART_URL)).must_equal "c21f969b5f03d33d43e04f8f136e7682"
      url = "https://res.cloudinary.com/uv7kncpy/image/upload/faa79416b855ca1c82b6b5aeb3c3235a.jpg"
      _(GithubProjectCard.art_id(url)).must_equal "faa79416b855ca1c82b6b5aeb3c3235a"
    end

    it "builds --mana-cost from rounded log10 of top language bytes minus 1, then mapped pips by usage" do
      # (Math.log10(77928) - 1).round => 4, Ruby (red) => R
      _(args_for("appraisal")[:mana_cost]).must_equal "4R"
      # (Math.log10(332697) - 1).round => 5, Ruby (red) then Shell (white) => RW
      _(args_for("mtg_card_maker")[:mana_cost]).must_equal "5RW"
      # (Math.log10(50328) - 1).round => 4, JavaScript (blue) then Ruby (red) => UR
      _(args_for("exercism-solutions")[:mana_cost]).must_equal "4UR"
      # (Math.log10(40627) - 1).round => 4, Python (green) => G
      _(args_for("UO-Macros")[:mana_cost]).must_equal "4G"
      # (Math.log10(194) - 1).round => 1, JavaScript (blue) => U
      _(args_for("zoom-close")[:mana_cost]).must_equal "1U"
    end

    it "groups identical pips together, ordered by first appearance in usage order" do
      # Top language is SCSS (31756). (Math.log10(31756) - 1).round => 4
      # SCSS W, HTML W, Ruby R, CSS U, JavaScript U => WW R UU
      _(args_for("joe-sharp.github.io")[:mana_cost]).must_equal "4WWRUU"
      # Top language HTML (20187). (Math.log10(20187) - 1).round => 3
      # HTML W, CSS U, JavaScript U => W UU
      _(args_for("agreen.studio")[:mana_cost]).must_equal "3WUU"
    end

    describe "with more than 5 languages" do
      # Ruby R, Shell W, SCSS W, HTML W, CSS U, JavaScript U, Python G
      let(:languages) do
        { "Ruby" => 70_000, "Shell" => 60_000, "SCSS" => 50_000, "HTML" => 40_000,
          "CSS" => 30_000, "JavaScript" => 20_000, "Python" => 10_000 }
      end

      it "limits --type-line to the top 5 languages" do
        _(args_for("appraisal", languages: languages)[:type_line]).must_equal "Ruby, Shell, SCSS, HTML, CSS"
      end

      it "caps each color at two pips and adds one generic mana per skipped pip" do
        # (Math.log10(70000) - 1).round => 4; W appears 3 times => 1 skipped => 5
        # Pips by first appearance: R, WW, UU, G
        _(args_for("appraisal", languages: languages)[:mana_cost]).must_equal "5RWWUUG"
      end
    end

    it "does not cap pips when the type-line is not truncated" do
      languages = { "Ruby" => 50_000, "Shell" => 40_000, "SCSS" => 30_000, "HTML" => 20_000, "CSS" => 10_000 }
      # W appears 3 times and is kept; (Math.log10(50000) - 1).round => 4
      _(args_for("appraisal", languages: languages)[:mana_cost]).must_equal "4RWWWU"
    end

    it "omits mana cost when there are no languages" do
      _(args_for("linter-configs")[:mana_cost]).must_be_nil
      _(args_for("ZoeDreams")[:mana_cost]).must_be_nil
    end

    it "joins language names by usage for --type-line" do
      _(args_for("appraisal")[:type_line]).must_equal "Ruby"
      _(args_for("mtg_card_maker")[:type_line]).must_equal "Ruby, Shell"
      _(args_for("exercism-solutions")[:type_line]).must_equal "JavaScript, Ruby"
      _(args_for("joe-sharp.github.io")[:type_line]).must_equal "SCSS, HTML, Ruby, CSS, JavaScript"
      _(args_for("linter-configs")[:type_line]).must_equal ""
    end

    it "uses description as --rules-text and empty string when description is nil" do
      _(args_for("agreen.studio")[:rules_text]).must_equal "Website for Anita Green"
      _(args_for("ZoeDreams")[:rules_text]).must_equal ""
      _(args_for("zoom-close")[:rules_text]).must_equal ""
    end

    it "names the original repo in --flavor-text for forks, in place of the created date" do
      _(args_for("appraisal", fork: true, parent_full_name: "thoughtbot/appraisal")[:flavor_text]).must_equal(
        "https://github.com/joe-sharp/appraisal\nappraisal, forked from thoughtbot/appraisal"
      )
    end

    it "falls back to the created date when a fork has no known parent" do
      _(args_for("appraisal", fork: true, parent_full_name: nil)[:flavor_text]).must_equal(
        "https://github.com/joe-sharp/appraisal\nCreated: 2021-10-14"
      )
    end

    it "builds --flavor-text as the repo URL plus a labeled date without UTC time" do
      _(args_for("agreen.studio")[:flavor_text]).must_equal(
        "https://github.com/joe-sharp/agreen.studio\nCreated: 2020-12-02"
      )
      _(args_for("joe-sharp.github.io")[:flavor_text]).must_equal(
        "https://github.com/joe-sharp/joe-sharp.github.io\nCreated: 2020-11-26"
      )
    end

    it "gives non-fork repos silver, or gold once stars plus forks reach 10" do
      _(args_for("appraisal")[:border_color]).must_equal "silver" # 0 stars, 0 forks
      _(args_for("appraisal", stargazers_count: 9)[:border_color]).must_equal "silver"
      _(args_for("appraisal", stargazers_count: 6, forks_count: 3)[:border_color]).must_equal "silver"
      _(args_for("appraisal", stargazers_count: 6, forks_count: 4)[:border_color]).must_equal "gold"
      _(args_for("appraisal", stargazers_count: 10_000)[:border_color]).must_equal "gold"
    end

    it "gives forks a white border whatever their popularity" do
      fork = { fork: true, parent_full_name: "thoughtbot/appraisal" }
      _(args_for("appraisal", **fork)[:border_color]).must_equal "white"
      _(args_for("appraisal", **fork, stargazers_count: 10_000)[:border_color]).must_equal "white"
    end

    it "uses stargazers as --power and forks as --toughness" do
      _(args_for("mtg_card_maker")[:power]).must_equal 2
      _(args_for("mtg_card_maker")[:toughness]).must_equal 1
      _(args_for("exercism-solutions")[:power]).must_equal 0
      _(args_for("exercism-solutions")[:toughness]).must_equal 3
    end

    it "uses the most-used language color unless two or more languages are at least 15% of bytes" do
      _(args_for("appraisal")[:color]).must_equal "red"
      _(args_for("UO-Macros")[:color]).must_equal "green"
      _(args_for("zoom-close")[:color]).must_equal "blue"
      # Shell is 131 / 332828 of mtg_card_maker, well under 15%
      _(args_for("mtg_card_maker")[:color]).must_equal "red"
      # JavaScript 50328 and Ruby 20677 are both >= 15% of 71005
      _(args_for("exercism-solutions")[:color]).must_equal "gold"
      # SCSS and HTML are both >= 15% of joe-sharp.github.io
      _(args_for("joe-sharp.github.io")[:color]).must_equal "gold"
      # HTML and CSS are both >= 15% of agreen.studio
      _(args_for("agreen.studio")[:color]).must_equal "gold"
      _(args_for("linter-configs")[:color]).must_equal "colorless"
      _(args_for("ZoeDreams")[:color]).must_equal "colorless"
    end
  end
  describe "#to_add_card_argv" do
    def argv_for(name, **)
      GithubProjectCard.new(fixture_project(name)).to_add_card_argv(**)
    end

    it "returns one unquoted --flag=value entry per flag, with no shell quoting" do
      argv = argv_for("mtg_card_maker", deck: "out.yml")

      _(argv.first(3)).must_equal %w[mtg_card_maker add_card out.yml]
      _(argv).must_include "--name=mtg_card_maker"
      _(argv).must_include "--type-line=Ruby, Shell"
      _(argv).must_include "--power=2"
    end

    it "swaps in the given art and exposes the expected art url" do
      card = GithubProjectCard.new(fixture_project("appraisal"))

      _(card.art_url).must_match %r{\Ahttps://res\.cloudinary\.com/uv7kncpy/image/upload/#{GithubProjectCard::ART_TRANSFORMATION}/\h{32}\.jpg\z}o
      _(argv_for("appraisal", art: "https://example.com/x.jpg")).must_include "--art=https://example.com/x.jpg"
      _(argv_for("appraisal")).must_include "--art=#{card.art_url}"
    end
  end

  describe "fork pull requests" do
    let(:fork_attributes) do
      fixture_project("appraisal").merge("fork" => true, "parent_full_name" => "thoughtbot/appraisal")
    end

    def pull_request(title, state)
      { "title" => title, "html_url" => "https://github.com/thoughtbot/appraisal/pull/#{title.length}", "state" => state }
    end

    def card_with(pull_requests, total: pull_requests.size)
      GithubProjectCard.new(fork_attributes.merge("pull_requests" => pull_requests, "pull_requests_total" => total))
    end

    it "lists up to five PRs, one per line, each with a status symbol" do
      card = card_with([pull_request("Fix thing", "merged"),
                        pull_request("Idea", "open"),
                        pull_request("Nope", "closed")])

      _(card.to_add_card_args[:rules_text]).must_equal "✓: Fix thing
●: Idea
✕: Nope"
    end

    it "summarises more than five PRs, leaving out zero counts" do
      merged = Array.new(5) { |i| pull_request("Merged #{i}", "merged") }
      card = card_with(merged + [pull_request("Open", "open")], total: 6)

      _(card.to_add_card_args[:rules_text]).must_equal "6 PRs to thoughtbot/appraisal: 5 merged, 1 open"
    end

    it "keeps the repo description when a fork has no PR data" do
      _(GithubProjectCard.new(fork_attributes).to_add_card_args[:rules_text]).must_equal(
        fixture_project("appraisal")["description"]
      )
    end

    it "keeps the repo description when a fork has no PRs into its parent" do
      _(card_with([], total: 0).to_add_card_args[:rules_text]).must_equal fixture_project("appraisal")["description"]
    end

    it "cuts long PR lines to the card width and turns braces into parentheses" do
      title = "Use {this} #{"word " * 20}"
      text = card_with([pull_request(title, "open")]).to_add_card_args[:rules_text]

      _(text.length).must_equal 50
      _(text.end_with?("\u2026")).must_equal true
      _(text).wont_include "{"
    end

    it "links each listed PR to its page" do
      card = card_with([pull_request("Fix thing", "merged")])

      _(card.rules_links).must_equal(
        [{ "href" => "https://github.com/thoughtbot/appraisal/pull/9", "label" => "Fix thing" }]
      )
    end

    it "links a summary to your PRs in the parent repo" do
      card = card_with(Array.new(6) { |i| pull_request("PR #{i}", "merged") }, total: 6)

      _(card.rules_links).must_equal(
        [{
          "href" => "https://github.com/thoughtbot/appraisal/pulls?q=is%3Apr+author%3Ajoe-sharp",
          "label" => "6 PRs to thoughtbot/appraisal: 6 merged"
        }]
      )
    end

    it "sends each PR on its own line to the card CLI as an escaped newline" do
      card = card_with([pull_request("One", "merged"), pull_request("Two", "open")])
      flag = card.to_add_card_argv.find { |arg| arg.start_with?("--rules-text=") }

      _(flag).must_equal "--rules-text=\u2713: One\\n\u25CF: Two"
    end

    it "sends a multi-line flavor text as an escaped newline" do
      flag = GithubProjectCard.new(fixture_project("appraisal")).to_add_card_argv.find { |arg|
        arg.start_with?("--flavor-text=")
      }

      _(flag).must_equal "--flavor-text=https://github.com/joe-sharp/appraisal\\nCreated: 2021-10-14"
    end

    it "has no links without PR data" do
      _(GithubProjectCard.new(fork_attributes).rules_links).must_equal []
    end
  end
end
