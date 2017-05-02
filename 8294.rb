begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  gem "rails", path: "../rails"
  #gem "arel", github: "rails/arel"
end

require "action_controller/railtie"

class TestApp < Rails::Application
  config.root = File.dirname(__FILE__)
  secrets.secret_token    = "secret_token"
  secrets.secret_key_base = "secret_key_base"

  config.logger = Logger.new($stdout)
  Rails.logger  = config.logger

  routes.draw do
    class RackApp
      def call(env)
        [200, {"Content-Type" => "text/html"}, ["I'm Old Gregg"]]
      end
    end

    mount RackApp.new, at: "/test"
  end
end

class TestController < ActionController::Base
  include Rails.application.routes.url_helpers

  def index
    render plain: "Home"
  end
end

require "minitest/autorun"
require "rack/test"

class BugTest < ActionDispatch::IntegrationTest
  include Rack::Test::Methods

  def test_returns_success
    assert_routing "/test", controller: "test"
  end

  private
    def app
      Rails.application
    end
end
