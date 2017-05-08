begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  gem "rails", path: ENV["RAILS_REPO"]
  gem "arel", path: ENV["AREL_REPO"]
  gem "pry-byebug"
end

require "action_controller/railtie"

class TestApp < Rails::Application
  config.root = File.dirname(__FILE__)
  config.session_store :cookie_store, key: "cookie_store_key"
  secrets.secret_token    = "secret_token"
  secrets.secret_key_base = "secret_key_base"

  config.logger = Logger.new($stdout)
  Rails.logger  = config.logger

  routes.draw do
    resources :users, only: [:index]
  end
end

class UsersController < ActionController::Base
  include Rails.application.routes.url_helpers
  def index
    unless cookies[:name].present?
      cookies[:name] = "Alice"
    end
    render plain: "Home"
  end
end

require "minitest/autorun"
require "rack/test"

class UsersControllerTest < ActionController::TestCase
  setup do
    @controller = UsersController.new
    @routes = Rails.application.routes
  end

  test '#index sets a cookie if it is not already present' do
    get :index
    assert_response :ok
    assert_equal "Alice", cookies[:name]

    cookies[:name] = "Bob"

    get :index
    assert_response :ok
    assert_equal "Bob", cookies[:name]
  end
end
