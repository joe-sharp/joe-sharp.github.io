# frozen_string_literal: true

require "yaml"

require_relative "github_project_card"

# Fetches a user's GitHub projects and wraps each one in a GithubProjectCard
module GithubProjectCards
  FAVORITES_FILE = File.join(__dir__, "../_data/favorites.yml")

  module_function

  def fetch(username:, fetcher:, favorites: load_favorites)
    payload = fetcher.call(username: username)
    projects = order(payload["projects"] || [], favorites)

    projects.map { |project| GithubProjectCard.new(project) }
  end

  def load_favorites
    YAML.load_file(FAVORITES_FILE)
  end

  # Favorites come first, in the order they are listed. Everything else follows by updated_at.
  def order(projects, favorites)
    pinned = favorites.filter_map { |name| projects.find { |project| project["name"] == name } }
    rest = projects.reject { |project| favorites.include?(project["name"]) }

    pinned + sort_by_updated(rest)
  end

  # Most recently updated first. GitHub timestamps share one sortable format, so
  # comparing the strings orders them by time; the name only breaks exact ties.
  def sort_by_updated(projects)
    projects.sort_by { |project| [project["updated_at"].to_s, project["name"].to_s] }.reverse
  end
end
