begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  gem "rails", github: "rails/rails"
  gem "arel", github: "rails/arel"
  gem "sqlite3"
end

require "active_record"
require "minitest/autorun"
require "logger"

# Ensure backward compatibility with Minitest 4
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
    t.string :title
  end
end

class NullType < ActiveRecord::Type::Value
  def serialize(value)
    nil
  end
end

ActiveRecord::Type.register(:null, NullType)

class Post < ActiveRecord::Base
  attribute :title, :null
end

class BugTest < Minitest::Test
  def test_nil_query
    assert_equal "SELECT \"posts\".* FROM \"posts\" WHERE \"posts\".\"title\" IS NULL", Post.where(title: NullType.new).to_sql
  end
end
