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
  gem "mysql2"
  gem "pg"
end

require "active_record"
require "minitest/autorun"
require "logger"

# This connection will do for database-independent bug reports.
#ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

def define_schema
  ActiveRecord::Schema.define do
    drop_table(:posts, if_exists: true)
    create_table :posts do |t|
      t.integer :author_id
      t.string :author_stuff
    end

    drop_table(:authors, if_exists: true)
    create_table :authors do |t|
      t.string :stuff
    end
  end
end

class Post < ActiveRecord::Base
  belongs_to :author
end

class Author < ActiveRecord::Base
end

class DatabaseTest < Minitest::Unit::TestCase
  def test_update_all_pg
    ActiveRecord::Base.establish_connection(adapter: 'postgresql', database: 'rails')

    define_schema

    Post.joins(:author).update_all('author_stuff = authors.stuff')
  end

  def test_update_all_mysql
    ActiveRecord::Base.establish_connection(adapter: 'mysql2', database: 'rails', username: 'rails')

    define_schema

    Post.joins(:author).update_all('author_stuff = authors.stuff')
  end

  def test_update_all_sqlite
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

    define_schema

    Post.joins(:author).update_all('author_stuff = authors.stuff')
  end
end
