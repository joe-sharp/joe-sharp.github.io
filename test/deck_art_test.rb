# frozen_string_literal: true

require 'test_helper'
require 'yaml'
require 'github_project_card'

# Every card needs a local copy of its art, or the site's fallback has nothing to show.
describe 'deck art fallbacks' do
  mirror_dir = File.expand_path('../images/art', __dir__)
  deck = YAML.load_file(File.expand_path('../_data/deck.yml', __dir__))

  deck.each_value do |card|
    it "has a local copy of the art for #{card['name']}" do
      id = GithubProjectCard.art_id(card['art'])

      _(File.exist?(File.join(mirror_dir, "#{id}.webp"))).must_equal true
    end
  end
end
