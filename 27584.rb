begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  gem "rails", path: ENV["RAILS_REPO"]
end

require "action_controller/railtie"

class TestApp < Rails::Application
  config.root = File.dirname(__FILE__)
  secrets.secret_token    = "secret_token"
  secrets.secret_key_base = "secret_key_base"

  config.logger = Logger.new($stdout)
  Rails.logger  = config.logger

  routes.draw do
    get "/" => "test#index"
    post "/" => "test#index"
    patch "/" => "test#index"
    put "/" => "test#index"
    delete "/" => "test#index"
  end
end

class TestController < ActionController::Base
  include Rails.application.routes.url_helpers

  def index
    cookies.delete("foo")
    render plain: "Home"
  end

  def foo_cookie
    cookies["foo"]
  end
end

require "rails/test_help"
require "minitest/autorun"

class TestControllerTest < ActionController::TestCase
  setup do
    cookies["foo"] = "bar"
  end

  test "cookies is deleted (get)" do
    get :index
    assert_nil cookies["foo"]
  end

  test "cookies is deleted (post)" do
    post :index
    assert_nil cookies["foo"]
  end

  test "cookies is deleted (patch)" do
    patch :index
    assert_nil cookies["foo"]
  end

  test "cookies is deleted (put)" do
    put :index
    assert_nil cookies["foo"]
  end

  test "cookies is deleted (delete)" do
    delete :index
    assert_nil cookies["foo"]
  end

  test "accessing helper method (get)" do
    get :index
    assert_nil @controller.foo_cookie
  end

  test "accessing helper method (post)" do
    post :index
    assert_nil @controller.foo_cookie
  end

  test "accessing helper method (patch)" do
    patch :index
    assert_nil @controller.foo_cookie
  end

  test "accessing helper method (put)" do
    put :index
    assert_nil @controller.foo_cookie
  end

  test "accessing helper method (delete)" do
    delete :index
    assert_nil @controller.foo_cookie
  end
end
