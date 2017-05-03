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

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :orders, force: true do |t|
    t.integer :customer_id
    t.boolean :confirmed
  end

  create_table :customers, force: true do |t|
    t.integer :post_id
  end
end

class Order < ActiveRecord::Base
  belongs_to :customer
  default_scope { where(confirmed: false) }
end

class Customer < ActiveRecord::Base
  has_many :confirmed_orders, -> { unscope(where: :confirmed).where(confirmed: true) },
    class_name: "Order"
end

class BugTest < Minitest::Test
  def test_association_stuff
    order = Order.create
    refute order.confirmed

    buyer = Customer.create
    buyer_order = buyer.confirmed_orders.create
    assert buyer_order.confirmed
  end
end
