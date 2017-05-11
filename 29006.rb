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
  create_table :posts, force: true do |t|
    t.column :status, :integer, default: 0, null: false
    t.integer :post_type, default: 0, null: false
  end

end

class Post < ActiveRecord::Base
  enum status: { active: 0, archived: 1 }
  enum post_type: { blog: 0, article: 1 }
end

class BugTest < Minitest::Test
  def test_association_stuff
    assert_equal 0, Post.statuses[:active]
    assert_equal 1, Post.statuses[:archived]
    assert_equal 0, Post.post_types[:blog]
    assert_equal 1, Post.post_types[:article]
  end
end
