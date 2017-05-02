begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  # gem "rails", '= 5.0.2'
  gem "rails", path: ENV["RAILS_REPO" 
  # gem "rails", path: '~/src/rails'
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
  end

  create_table :comments, force: true do |t|
    t.integer :post_id
    t.integer  :comment_color, default: 0, null: false
  end
end

class Post < ActiveRecord::Base
  has_many :comments
  has_many :warm_comments, -> { where(comment_color: [:red, :orange, :yellow]) }, class_name: 'Comment'

  def cool_comments
    comments.where(comment_color: [:blue, :green, :indigo])
  end
end

class Comment < ActiveRecord::Base
  belongs_to :post
  enum comment_color: {
    red: 0,
    orange: 1,
    yellow: 2,
    green: 3,
    indigo: 4,
    blue: 5
  }
end

class BugTest < Minitest::Test
  def setup
    @post = Post.create!
    @post.comments.create(
      [
        { comment_color: :red },
        { comment_color: :orange },
        { comment_color: :indigo },
        { comment_color: :blue },
        { comment_color: :green }
      ]
    )
  end

  def test_cool_comments
    # ✅ Rails 5.0.2:
    #   SELECT COUNT(*) FROM "comments" WHERE "comments"."post_id" = ? AND "comments"."comment_color" IN (5, 3, 4)  [["post_id", 2]]
    #
    # ✅ Rails 5.1.0:
    #   SELECT COUNT(*) FROM "comments" WHERE "comments"."post_id" = ? AND "comments"."comment_color" IN (5, 3, 4)  [["post_id", 2]]
    assert_equal 3, @post.cool_comments.count
  end

  def test_warm_comments
    # ✅ Rails 5.0.2:
    #   SELECT COUNT(*) FROM "comments" WHERE "comments"."post_id" = ? AND "comments"."comment_color" IN (0, 1, 2)  [["post_id", 2]]
    #
    # ⛔ Rails 5.1.0:
    #   SELECT COUNT(*) FROM "comments" WHERE "comments"."post_id" = ? AND "comments"."comment_color" IN ('red', 'orange', 'yellow')  [["post_id", 1]]
    assert_equal 2, @post.warm_comments.count

    # Git bisect suggests that this behavior changed as of commit: 
    #   https://github.com/rails/rails/commit/111ccc8
    # Which was a fix for #27666:
    #   https://github.com/rails/rails/issues/27666
  end
end
