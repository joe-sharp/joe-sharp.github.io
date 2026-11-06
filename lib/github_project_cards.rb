# frozen_string_literal: true

require_relative "github_project_card"

# Fetches a user's GitHub projects and wraps each one in a GithubProjectCard
module GithubProjectCards
  module_function

  def fetch(username:, fetcher:)
    payload = fetcher.call(username: username)
    projects = sort_by_updated(payload["projects"] || [])

    projects.map { |project| GithubProjectCard.new(project) }
  end

  # Most recently updated first. GitHub timestamps share one sortable format, so
  # comparing the strings orders them by time; the name only breaks exact ties.
  def sort_by_updated(projects)
    projects.sort_by { |project| [project["updated_at"].to_s, project["name"].to_s] }.reverse
  end
end
