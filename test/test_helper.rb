# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'minitest/autorun'
require 'minitest/spec'
require 'json'

module FixtureHelper
  FIXTURE_PATH = File.expand_path('fixtures/projects.json', __dir__)

  def fixture_payload
    JSON.parse(File.read(FIXTURE_PATH))
  end

  def fixture_projects
    fixture_payload.fetch('projects')
  end

  def fixture_project(name)
    fixture_projects.find { |project| project['name'] == name } ||
      raise(KeyError, "No fixture project named #{name.inspect}")
  end
end
