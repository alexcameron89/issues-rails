begin
  require 'bundler/inline'
rescue LoadError => e
  $stderr.puts 'Bundler version 1.10 or later is required. Please update your Bundler'
  raise e
end

gemfile(true) do
  source 'https://rubygems.org'
  gem 'rails', path: "../rails"
  gem 'sqlite3'
end

require 'active_record'
require 'minitest/autorun'
require 'logger'

Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :users, force: true

  create_table :roles, force: true do |t|
    t.boolean :direct, null: false, default: false
  end

  create_table :institutions, force: true

  create_table :appointments, force: true do |t|
    t.references :user
    t.references :role
    t.references :institution
  end
end

class User < ActiveRecord::Base
end

class Role < ActiveRecord::Base
  scope :direct, ->{ where(direct: true) }
end

class Institution < ActiveRecord::Base
  has_many :direct_appointments, ->{ joins(:role).merge(Role.direct) }, class_name: 'Appointment'
  has_many :direct_users, through: :direct_appointments, source: :user
end

class Appointment < ActiveRecord::Base
  belongs_to :role
  belongs_to :institution
  belongs_to :user
end

class BugTest < Minitest::Test
  def test_association
    Appointment.create(role: Role.create(direct: true), institution: Institution.create, user: User.create)
    Institution.first.direct_users.to_a
    assert true
  end
end
