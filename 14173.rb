begin
  require 'bundler/inline'
rescue LoadError => e
  $stderr.puts 'Bundler version 1.10 or later is required. Please update your Bundler'
  raise e
end

gemfile(true) do
  source 'https://rubygems.org'
  gem 'rails', github: 'rails/rails'
  gem 'arel', github: 'rails/arel'
end

require 'action_controller/railtie'

class TestApp < Rails::Application
  config.root = File.dirname(__FILE__)
  config.session_store :cookie_store, key: 'cookie_store_key'
  secrets.secret_token    = 'secret_token'
  secrets.secret_key_base = 'secret_key_base'

  config.logger = Logger.new($stdout)
  Rails.logger  = config.logger

  routes.draw do
    get '/' => 'test#index'
  end
end

unless File.exist?('test.xml.erb')
  File.write('test.xml.erb', <<-TEMPLATE)
        <foo>Hello World!</foo>
  TEMPLATE
end

class TestController < ActionController::Base
  include Rails.application.routes.url_helpers

  def index
    render_to_string file: File.expand_path('../test', __FILE__), formats: [:xml], layout: false
    render text: '<p>hello world</p>'
  end
end

require 'minitest/autorun'
require 'rack/test'

class BugTest < Minitest::Test
  include Rack::Test::Methods

  def test_returns_success
    get '/'
    assert last_response.ok?
    assert_equal '<p>hello world</p>', last_response.body
    assert_equal 'text/html; charset=utf-8', last_response.headers['Content-Type']
  end

  private
  def app
    Rails.application
  end
end
