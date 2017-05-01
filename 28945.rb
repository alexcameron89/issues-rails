begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  # Activate the gem you are reporting the issue against.
  gem "activerecord", github: "rails/rails"
  gem "arel",         github: "rails/arel"
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
  create_table :measures, force: true do |t|
    t.integer :Disposal_Unit
  end

end

class Measure < ActiveRecord::Base
  alias_attribute :disposal_unit, :Disposal_Unit

  enum disposal_unit: {
    cubic_meter: 1,
    tons: 2,
    no_data: 0,
    nothing: nil
  }
end

class BugTest < Minitest::Test
  def test_nil_enum_query
    assert_equal "SELECT \"measures\".* FROM \"measures\" WHERE \"measures\".\"Disposal_Unit\" IS NULL", Measure.nothing.to_sql
  end
end
