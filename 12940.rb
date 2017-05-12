begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  gem "rails", path: ENV["RAILS_REPO"]
  #gem "arel", github: "rails/arel"
end

require 'action_controller/railtie'
require 'minitest/autorun'

begin
  # Engine code looks for its root by finding lib
  # Clean this up in the ensure block
  FileUtils.mkdir('lib')

  module Example
    class Engine < Rails::Engine; end
  end

  class HostApplication < Rails::Application
    config.eager_load = false
  end

  HostApplication.initialize!

  Example::Engine.routes.draw do
    get '/foo', to: 'foo#show', as: 'foo'
  end

  class Example::ApplicationControllerBeforeIsolation < ActionController::Base; end

  Example::Engine.isolate_namespace Example

  class Example::ApplicationControllerAfterIsolation < ActionController::Base; end

  module OtherNameSpace
    class ControllerBefore < ::Example::ApplicationControllerBeforeIsolation; end
    class ControllerAfter < ::Example::ApplicationControllerAfterIsolation; end
  end

  class EngineTest < ActiveSupport::TestCase
    def test_app_url_helpers_dont_leak_into_engine_controller_in_different_namespace
      assert_equal [].to_set, OtherNameSpace::ControllerBefore.action_methods
      assert_equal [].to_set, Example::ApplicationControllerAfterIsolation.action_methods
      # the line below currently fails
      assert_equal [].to_set, OtherNameSpace::ControllerAfter.action_methods
    end
  end
ensure
  FileUtils.rm_rf('lib')
  FileUtils.rm_rf('log')
end
