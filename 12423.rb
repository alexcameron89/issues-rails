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
  create_table :blogs, :force => true do |t|
  end

  create_table :posts, :force => true do |t|
    t.integer :blog_id
  end
end

class Blog < ActiveRecord::Base
  has_many :posts, :dependent => :destroy
end

class Post < ActiveRecord::Base
  belongs_to :blog
end

class TestMe < MiniTest::Test
  def test_includes_with_additional_column
    blog = Blog.create!
    blogs = Blog.select(Blog.column_names + ["'foo' as foo"]).references(:posts).includes(:posts).order('foo').to_a
    assert_equal [blog], blogs
    assert_equal 'foo', blogs.first.foo
  end
end
