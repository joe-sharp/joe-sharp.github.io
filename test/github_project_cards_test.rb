# frozen_string_literal: true

require 'test_helper'
require 'github_project_cards'

describe GithubProjectCards do
  include FixtureHelper

  let(:payload) { fixture_payload }

  def stub_fetcher
    lambda do |username:|
      _(username).must_equal 'joe-sharp'
      payload
    end
  end

  describe '.fetch' do
    it 'loads projects from the stubbed endpoint payload without hitting the network' do
      cards = GithubProjectCards.fetch(username: 'joe-sharp', fetcher: stub_fetcher)

      _(cards.size).must_equal fixture_projects.size
      _(cards.map { |card| card.to_add_card_args[:name] }).must_equal(
        fixture_projects.map { |project| project['name'] }
      )
    end
  end

  describe '#to_add_card_command' do
    def command_for(name)
      project = fixture_project(name)
      GithubProjectCards.fetch(username: 'joe-sharp', fetcher: ->(**) { { 'projects' => [project] } })
                        .first
                        .to_add_card_command
    end

    it 'emits an mtg_card_maker add_card command with quoted flags' do
      command = command_for('mtg_card_maker')

      _(command).must_match(/\Amtg_card_maker add_card deck.yml /)
      _(command).must_include '--name="mtg_card_maker"'
      _(command).must_include '--art="https://res.cloudinary.com/uv7kncpy/image/upload/595f103c608631e0049772bf3ad48b06.jpg"'
      _(command).must_include '--mana-cost="5RW"'
      _(command).must_include '--type-line="Ruby, Shell"'
      _(command).must_include '--color="red"'
      _(command).must_include '--border-color="white"'
      _(command).must_include '--power="2"'
      _(command).must_include '--toughness="1"'
      _(command).must_include '--rules-text="'
      _(command).must_include '--flavor-text="'
    end

    it 'quotes type-line when it contains spaces and commas' do
      command = command_for('joe-sharp.github.io')

      _(command).must_include '--name="joe-sharp.github.io"'
      _(command).must_include '--art="https://res.cloudinary.com/uv7kncpy/image/upload/faa79416b855ca1c82b6b5aeb3c3235a.jpg"'
      _(command).must_include '--type-line="SCSS, HTML, Ruby, CSS, JavaScript"'
      _(command).must_include '--color="gold"'
    end

    it 'omits --mana-cost when languages are empty' do
      command = command_for('ZoeDreams')

      _(command).wont_include '--mana-cost='
      _(command).must_include '--rules-text=""'
      _(command).must_include '--type-line=""'
      _(command).must_include '--color="colorless"'
    end
  end
end
