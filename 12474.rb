begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  gem "rails", "5.1.0"
  gem "sqlite3"
end

require "active_record"
require "minitest/autorun"
require "logger"

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table "places", force: true do |t|
    t.string   "name"
    t.string   "type"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "places", ["parent_id"], name: "index_places_on_parent_id"
end

# This is the parent class for each model defined below
# - Place
# | - Country
# | - City
# | - District
class Place < ActiveRecord::Base
  belongs_to :parent
end

class Country < Place

  has_many :cities, foreign_key: 'parent_id'

  has_many :districts, through: :cities, foreign_key: 'parent_id'
end

class City < Place

  belongs_to :country, foreign_key: 'parent_id'

  has_many :districts, foreign_key: 'parent_id'
end

class District < Place

  belongs_to :city, foreign_key: "parent_id"

end

class BugTest < MiniTest::Unit::TestCase
  def test_has_many_sti
    # Create a bunch of records
    country  = Country.create(name: "USA")
    city     = country.cities.create(name: "Seattle")
    district = city.districts.create(name: "Capitol Hill")

    # I would expect these to be equal - they're not.
    assert_equal Country.first.cities.map(&:districts), [Country.first.districts]
    # This should be true
    assert_equal Country.first.cities.map(&:districts).flatten, Country.first.districts # => false
  end
end
