begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  # Activate the gem you are reporting the issue against.
  gem "activerecord", "5.1.0"
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
  create_table :users, force: true do |t|
  end

  create_table :roles, force: true do |t|
    t.string  :role
    t.integer :user_id
  end
end

class User < ActiveRecord::Base
  has_many :roles
end

class Role < ActiveRecord::Base
  belongs_to :user
end

class BugTest < Minitest::Test
  def test_exists_query
    user = User.create!
    user.roles << Role.create!(role: "teacher")

    assert_equal 1, user.roles.count
    assert_equal 1, Role.count
    assert_equal user.id, Role.first.user.id

    assert_equal "SELECT \"users\".* FROM \"users\" WHERE (exists (select 'X' from roles where roles.role = 'teacher' and roles.user_id = users.id))", User.where("exists (select 'X' from roles where roles.role = 'teacher' and roles.user_id = users.id)").to_sql
  end

end
