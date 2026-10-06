# frozen_string_literal: true

require 'test_helper'
require 'github_project_card'

describe GithubProjectCard do
  include FixtureHelper

  def args_for(name, **overrides)
    GithubProjectCard.new(fixture_project(name).merge(overrides.transform_keys(&:to_s))).to_add_card_args
  end

  it 'maps color names to mana pips in a constant' do
    _(GithubProjectCard::COLOR_MANA_CODE).must_equal(
      {
        'blue' => 'U',
        'black' => 'B',
        'white' => 'W',
        'red' => 'R',
        'green' => 'G'
      }
    )
  end

  describe '#to_add_card_args' do
    it 'uses the repo name for --name' do
      _(args_for('appraisal')[:name]).must_equal 'appraisal'
      _(args_for('joe-sharp.github.io')[:name]).must_equal 'joe-sharp.github.io'
    end

    it 'uses a Cloudinary URL with an MD5 checksum of the repo name as the art' do
      base = 'https://res.cloudinary.com/uv7kncpy/image/upload'
      # Digest::MD5.hexdigest('joe-sharp.github.io')
      _(args_for('joe-sharp.github.io')[:art]).must_equal "#{base}/faa79416b855ca1c82b6b5aeb3c3235a.jpg"
      _(args_for('mtg_card_maker')[:art]).must_equal "#{base}/595f103c608631e0049772bf3ad48b06.jpg"
    end

    it 'builds --mana-cost from rounded log10 of top language bytes minus 1, then mapped pips by usage' do
      # (Math.log10(77928) - 1).round => 4, Ruby (red) => R
      _(args_for('appraisal')[:mana_cost]).must_equal '4R'
      # (Math.log10(332697) - 1).round => 5, Ruby (red) then Shell (white) => RW
      _(args_for('mtg_card_maker')[:mana_cost]).must_equal '5RW'
      # (Math.log10(50328) - 1).round => 4, JavaScript (blue) then Ruby (red) => UR
      _(args_for('exercism-solutions')[:mana_cost]).must_equal '4UR'
      # (Math.log10(40627) - 1).round => 4, Python (green) => G
      _(args_for('UO-Macros')[:mana_cost]).must_equal '4G'
      # (Math.log10(194) - 1).round => 1, JavaScript (blue) => U
      _(args_for('zoom-close')[:mana_cost]).must_equal '1U'
    end

    it 'groups identical pips together, ordered by first appearance in usage order' do
      # Top language is SCSS (31756). (Math.log10(31756) - 1).round => 4
      # SCSS W, HTML W, Ruby R, CSS U, JavaScript U => WW R UU
      _(args_for('joe-sharp.github.io')[:mana_cost]).must_equal '4WWRUU'
      # Top language HTML (20187). (Math.log10(20187) - 1).round => 3
      # HTML W, CSS U, JavaScript U => W UU
      _(args_for('agreen.studio')[:mana_cost]).must_equal '3WUU'
    end

    it 'omits mana cost when there are no languages' do
      _(args_for('linter-configs')[:mana_cost]).must_be_nil
      _(args_for('ZoeDreams')[:mana_cost]).must_be_nil
    end

    it 'joins language names by usage for --type-line' do
      _(args_for('appraisal')[:type_line]).must_equal 'Ruby'
      _(args_for('mtg_card_maker')[:type_line]).must_equal 'Ruby, Shell'
      _(args_for('exercism-solutions')[:type_line]).must_equal 'JavaScript, Ruby'
      _(args_for('joe-sharp.github.io')[:type_line]).must_equal 'SCSS, HTML, Ruby, CSS, JavaScript'
      _(args_for('linter-configs')[:type_line]).must_equal ''
    end

    it 'uses description as --rules-text and empty string when description is nil' do
      _(args_for('agreen.studio')[:rules_text]).must_equal 'Website for Anita Green'
      _(args_for('ZoeDreams')[:rules_text]).must_equal ''
      _(args_for('zoom-close')[:rules_text]).must_equal ''
    end

    it 'builds --flavor-text as the repo URL plus a labeled date without UTC time' do
      _(args_for('agreen.studio')[:flavor_text]).must_equal(
        "https://github.com/joe-sharp/agreen.studio\nCreated: 2020-12-02"
      )
      _(args_for('joe-sharp.github.io')[:flavor_text]).must_equal(
        "https://github.com/joe-sharp/joe-sharp.github.io\nCreated: 2020-11-26"
      )
    end

    it 'maps star-count log10 buckets to --border-color, treating zero stars as white' do
      _(args_for('appraisal')[:border_color]).must_equal 'white' # 0 stars
      _(args_for('linter-configs')[:border_color]).must_equal 'white' # 2 stars, log10(2).round => 0
      _(args_for('appraisal', stargazers_count: 10)[:border_color]).must_equal 'white' # log10(10).round => 1
      _(args_for('appraisal', stargazers_count: 100)[:border_color]).must_equal 'black' # log10(100).round => 2
      _(args_for('appraisal', stargazers_count: 1000)[:border_color]).must_equal 'silver' # log10(1000).round => 3
      _(args_for('appraisal', stargazers_count: 10_000)[:border_color]).must_equal 'gold' # log10(10000).round => 4
    end

    it 'uses stargazers as --power and forks as --toughness' do
      _(args_for('mtg_card_maker')[:power]).must_equal 2
      _(args_for('mtg_card_maker')[:toughness]).must_equal 1
      _(args_for('exercism-solutions')[:power]).must_equal 0
      _(args_for('exercism-solutions')[:toughness]).must_equal 3
    end

    it 'uses the most-used language color unless two or more languages are at least 15% of bytes' do
      _(args_for('appraisal')[:color]).must_equal 'red'
      _(args_for('UO-Macros')[:color]).must_equal 'green'
      _(args_for('zoom-close')[:color]).must_equal 'blue'
      # Shell is 131 / 332828 of mtg_card_maker, well under 15%
      _(args_for('mtg_card_maker')[:color]).must_equal 'red'
      # JavaScript 50328 and Ruby 20677 are both >= 15% of 71005
      _(args_for('exercism-solutions')[:color]).must_equal 'gold'
      # SCSS and HTML are both >= 15% of joe-sharp.github.io
      _(args_for('joe-sharp.github.io')[:color]).must_equal 'gold'
      # HTML and CSS are both >= 15% of agreen.studio
      _(args_for('agreen.studio')[:color]).must_equal 'gold'
      _(args_for('linter-configs')[:color]).must_equal 'colorless'
      _(args_for('ZoeDreams')[:color]).must_equal 'colorless'
    end
  end
end
