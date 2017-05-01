begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  gem "rails"#, github: "rails/rails"
  gem "arel"#, github: "rails/arel"
end

require "action_controller/railtie"
require "minitest/autorun"

class BugTest < Minitest::Test
  def test_routes
    rs = ::ActionDispatch::Routing::RouteSet.new
    rs.draw do
      resources :searches do
        collection do
          match '(/:catalog_number(/:manufacturer(/:replacements)))' => "searches#index", :as => :search, :via => :get
        end
      end
    end

    x = Class.new {
      include rs.url_helpers
    }
    assert_equal '/searches', x.new.search_searches_path
    assert_equal '/searches/123', x.new.search_searches_path(123)
    assert_equal '/searches/123/fuzz', x.new.search_searches_path(123, 'fuzz')
    assert_equal '/searches/123/fuzz/1', x.new.search_searches_path(123, 'fuzz', 1)
    assert_equal '/searches/123?requirements=1', x.new.search_searches_path(123, nil, 1)
    assert_equal '/searches/123/fuzz/1?replacements=2', x.new.search_searches_path(123, 'fuzz', 1, :replacements => 2)
  end
end
