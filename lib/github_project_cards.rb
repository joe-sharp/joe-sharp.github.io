# frozen_string_literal: true

require_relative 'github_project_card'

module GithubProjectCards
  module_function

  def fetch(username:, fetcher:)
    payload = fetcher.call(username: username)
    projects = payload['projects'] || []

    projects.map { |project| GithubProjectCard.new(project) }
  end
end
