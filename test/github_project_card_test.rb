# frozen_string_literal: true

require 'test_helper'
require 'github_project_card'

describe GithubProjectCard do
  include FixtureHelper

  def args_for(name, **overrides)
    GithubProjectCard.new(fixture_project(name).merge(overrides.transform_keys(&:to_s))).to_add_card_args
  end

  it 'maps language names to mana pips in a constant' do
    _(GithubProjectCard::LANGUAGE_MANA).must_equal(
      {
        'Ruby' => 'R',
        'Python' => 'B',
        'JavaScript' => 'G',
        'Shell' => 'W'
      }
    )
  end

  describe '#to_add_card_args' do
    it 'uses the repo name for --name' do
      _(args_for('appraisal')[:name]).must_equal 'appraisal'
      _(args_for('joe-sharp.github.io')[:name]).must_equal 'joe-sharp.github.io'
    end

    it 'uses an MD5 checksum of the repo name as the PNG art filename' do
      # Digest::MD5.hexdigest('joe-sharp.github.io')
      _(args_for('joe-sharp.github.io')[:art]).must_equal 'faa79416b855ca1c82b6b5aeb3c3235a.png'
      _(args_for('mtg_card_maker')[:art]).must_equal '595f103c608631e0049772bf3ad48b06.png'
    end

    it 'builds --mana-cost from rounded log10 of top language bytes minus 1, then mapped pips by usage' do
      # (Math.log10(77928) - 1).round => 4, then R
      _(args_for('appraisal')[:mana_cost]).must_equal '4R'
      # (Math.log10(332697) - 1).round => 5, Ruby then Shell => RW
      _(args_for('mtg_card_maker')[:mana_cost]).must_equal '5RW'
      # (Math.log10(50328) - 1).round => 4, JavaScript then Ruby => GR
      _(args_for('exercism-solutions')[:mana_cost]).must_equal '4GR'
      # (Math.log10(40627) - 1).round => 4, Python => B
      _(args_for('UO-Macros')[:mana_cost]).must_equal '4B'
      # (Math.log10(194) - 1).round => 1, JavaScript => G
      _(args_for('zoom-close')[:mana_cost]).must_equal '1G'
    end

    it 'skips unmapped languages in pips but still uses the top language bytes for generic mana' do
      # Top language is SCSS (31756, unmapped). (Math.log10(31756) - 1).round => 4
      # Mapped pips in bytes-desc order: Ruby, JavaScript => RG
      _(args_for('joe-sharp.github.io')[:mana_cost]).must_equal '4RG'
      # Top language HTML (unmapped). (Math.log10(20187) - 1).round => 3, then JavaScript => G
      _(args_for('agreen.studio')[:mana_cost]).must_equal '3G'
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

    it 'builds --flavor-text as a markdown short link plus a labeled date without UTC time' do
      _(args_for('agreen.studio')[:flavor_text]).must_equal(
        "[joe-sharp/agreen.studio](https://github.com/joe-sharp/agreen.studio)\nCreated: 2020-12-02"
      )
      _(args_for('joe-sharp.github.io')[:flavor_text]).must_equal(
        "[joe-sharp/joe-sharp.github.io](https://github.com/joe-sharp/joe-sharp.github.io)\nCreated: 2020-11-26"
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
      _(args_for('UO-Macros')[:color]).must_equal 'black'
      _(args_for('zoom-close')[:color]).must_equal 'green'
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
