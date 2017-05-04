begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  gem "rails", path: "../rails"
  #gem "arel", path: "../arel"
  gem "sqlite3"
end

require "active_record"
require "minitest/autorun"
require "logger"

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :people do |t|
    t.string :type
    t.references :parent
  end

  create_table :toys do |t|
    t.references :child
  end
end

class Person < ActiveRecord::Base
end

class Child < Person
  belongs_to :parent
  has_many :toys
end

class Parent < Person
  has_many :children
  has_many :toys, through: :children
end

class Toy < ActiveRecord::Base
  belongs_to :child
  has_one :parent, through: :child
end

class BugTest < Minitest::Test
  def setup
    @parent = Parent.create!
    @child  = Child.create! parent: @parent
    @toy    = Toy.create! child: @child
  end

  def test_has_many_through
    assert_equal [@toy], @parent.toys
  end

  def test_has_one_through
    assert_equal @parent, @toy.parent
  end
end
