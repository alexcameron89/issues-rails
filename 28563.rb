begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  gem "rails", path: ENV["RAILS_REPO"]
  gem "arel", github: "rails/arel"
  gem "sqlite3"
end

require "active_record"
require "minitest/autorun"
require "logger"

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
  end
end

class User < ActiveRecord::Base
end

class BugTest < Minitest::Test
  def test_destroyed_frozen
    user = User.new
    user.save
    user.destroy
    user.save
    assert user.frozen?, "user should be frozen"
  end

  def test_saved_frozen
    user = User.new
    user.save
    user.freeze
    user.save
    assert user.frozen?, "user should be frozen"
  end

  def test_changed?
    User.create(name: "Alex")
    user = User.find(1)
    user.name += "hi"
    user.freeze

    user.save!

    refute user.changed?, "user should not have changed"
  end
end
