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
  create_table :posts do |t|
    t.string  :subject
  end

  create_table :comments do |t|
    t.integer :post_id
    t.integer :points
  end
end

class Post < ActiveRecord::Base
  has_many :comments

  scope :dewey, -> { order(subject: :desc) }
  scope :truman, -> { order(:subject) }
end

class Comment < ActiveRecord::Base
  belongs_to :post

  scope :decimal, -> { order(points: :desc) }
  scope :dewey_decimal, -> { decimal.joins(:post).merge(Post.dewey) }
  scope :truman_decimal, -> { decimal.joins(:post).merge(Post.truman) }
end

class BugTest < MiniTest::Unit::TestCase
  def test_association_stuff
    post1 = Post.create!(subject: "Awesomeness")
    comment1 = Comment.create!(post_id: post1.id, points: 5)
    comment2 = Comment.create!(post_id: post1.id, points: 9)
    post2 = Post.create!(subject: "Zaniness")
    comment3 = Comment.create!(post_id: post2.id, points: 9)
    comment4 = Comment.create!(post_id: post2.id, points: 3)

    assert_equal Comment.truman_decimal, [comment2, comment3, comment1, comment4]
    assert_equal Comment.dewey_decimal, [comment3, comment2, comment1, comment4]
  end
end
