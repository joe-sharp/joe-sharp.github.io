# frozen_string_literal: true

require 'test_helper'
require 'card_links'
require 'github_project_card'

describe CardLinks do
  let(:sprite) do
    <<~SVG
      <?xml version="1.0"?>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1320 910" width="0" height="0" aria-hidden="true">
        <defs>
        <g id="deck-card-0" transform="translate(0, 0)">
          <text x="55" y="633.3333333333334" fill="#111" font-size="24" class="card-rules-text">
      first line
          </text>
          <text x="55" y="659.8333333333334" fill="#111" font-size="24" class="card-rules-text">
      second line
          </text>
          <text x="55" y="712.8333333333334" fill="#111" font-size="24" class="card-flavor-text">
      flavor
          </text>
        </g>
        <g id="deck-card-1" transform="translate(660, 0)">
          <text x="55" y="633.3333333333334" fill="#111" font-size="24" class="card-rules-text">
      plain card
          </text>
        </g>
        </defs>
      </svg>
    SVG
  end

  def card(name, pull_requests: [], total: pull_requests.size, fork: true)
    GithubProjectCard.new(
      'name' => name,
      'fork' => fork,
      'html_url' => "https://github.com/joe-sharp/#{name}",
      'parent_full_name' => 'thoughtbot/appraisal',
      'pull_requests' => pull_requests,
      'pull_requests_total' => total
    )
  end

  def pr(title, number)
    { 'title' => title, 'html_url' => "https://github.com/thoughtbot/appraisal/pull/#{number}", 'state' => 'open' }
  end

  it 'places one box per listed PR, on that PR\'s rules line' do
    links = CardLinks.build(sprite, [card('appraisal', pull_requests: [pr('One', 1), pr('Two', 2)])])

    boxes = links.fetch('appraisal')
    _(boxes.map { |box| box['href'] }).must_equal %w[
      https://github.com/thoughtbot/appraisal/pull/1
      https://github.com/thoughtbot/appraisal/pull/2
    ]
    _(boxes.first['top']).must_equal CardLinks.percent(633.3333333333334 - CardLinks::BASELINE_OFFSET, 880)
    _(boxes.last['top']).must_equal CardLinks.percent(659.8333333333334 - CardLinks::BASELINE_OFFSET, 880)
    _(boxes.first['height']).must_equal CardLinks.percent(CardLinks::LINE_HEIGHT, 880)
  end

  it 'covers every rules line with one box for a summary' do
    summary = { 'href' => 'https://github.com/thoughtbot/appraisal/pulls?q=x', 'label' => '6 PRs' }
    boxes = CardLinks.build(sprite, [card('appraisal', pull_requests: [])]).fetch('appraisal', nil)
    _(boxes).must_be_nil

    links = CardLinks.boxes_for([summary], [633.3333333333334, 659.8333333333334])
    _(links.size).must_equal 1
    _(links.first['height']).must_equal CardLinks.percent(659.8333333333334 - 633.3333333333334 + CardLinks::LINE_HEIGHT, 880)
  end

  it 'leaves out cards without links, non-forks and cards missing from the sprite' do
    cards = [
      card('appraisal', pull_requests: []),
      card('plain', fork: false, pull_requests: [pr('Ignored', 3)])
    ]

    _(CardLinks.build(sprite, cards)).must_equal({})
  end

  it 'reads the rules lines of each card from its own group' do
    _(CardLinks.rules_baselines(sprite)).must_equal(
      0 => [633.3333333333334, 659.8333333333334],
      1 => [633.3333333333334]
    )
  end
end
