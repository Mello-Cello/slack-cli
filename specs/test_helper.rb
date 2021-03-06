require "simplecov"
SimpleCov.start

require "dotenv"
Dotenv.load

require "minitest/autorun"
require "minitest/reporters"
require "minitest/skip_dsl"
require "vcr"
require "webmock/minitest" # <-- do we need this?

require_relative "../lib/slack.rb"
# require_relative "../specs/slack_spec"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

VCR.configure do |config|
  config.cassette_library_dir = "specs/cassettes" # folder where casettes will be located
  config.hook_into :webmock # tie into this other tool called webmock
  config.default_cassette_options = {
    :record => :new_episodes,    # record new data when we don't have it yet
    :match_requests_on => [:method, :uri, :body], # The http method, URI and body of a request all need to match
  }
  # Don't leave our Slack token lying around in a cassette file.
  config.filter_sensitive_data("SLACK_API_TOKEN") do
    ENV["SLACK_API_TOKEN"]
  end
end
