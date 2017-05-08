begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  gem "rails", path: "../rails"
  gem "sqlite3"
  gem "minitest"
end

require "active_record"
require "minitest/autorun"
require "logger"

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :people
  create_table :houses do |t|
    t.references :person
  end
  create_table :colors do |t|
    t.references :house
    t.string :color
  end
  create_table :conditions do |t|
    t.string :condition
  end
  create_table :conditions_houses do |t|
    t.references :condition
    t.references :house
  end
end

class Color < ActiveRecord::Base
  belongs_to :house
end

class Condition < ActiveRecord::Base
  has_and_belongs_to_many :houses
end

class House < ActiveRecord::Base
  has_many :colors
  belongs_to :person

  has_and_belongs_to_many :conditions

  scope :damaged, -> { joins(:conditions).where('conditions.condition' => 'damaged') }
end

class Person < ActiveRecord::Base
  has_many :houses
  has_many :colors, :through => :houses

  has_many :damaged_houses, -> { damaged }, :class_name => "House"
  has_many :damaged_colors, through: :damaged_houses, :source => :colors
end

class BugTest < Minitest::Test
  def test_association_stuff
    Condition.create(condition: :damaged)
    house = House.create(conditions: [Condition.first])
    person = Person.create
    house.person = person
    color = Color.create
    house.colors = [color]
    house.save

    assert_equal 1, person.houses.count
    assert_equal 1, person.damaged_houses.count

    assert_equal 1, person.colors.count
    assert_equal 1, person.damaged_colors.count
  end
end
