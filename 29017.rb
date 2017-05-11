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
    t.string :title
    t.string :body
  end
end

class Post < ActiveRecord::Base
end

class BugTest < Minitest::Test
  def test_association_stuff
    Post.create!(title: "Bunya", body: "A bunny's name was Bunya.")

    post = Post.select(:title).first

    assert_equal "Bunya", post.title
    assert_raises ActiveModel::MissingAttributeError do
      post.body
    end

    post.save

    assert_raises ActiveModel::MissingAttributeError do
      post.body
    end
  end
end
