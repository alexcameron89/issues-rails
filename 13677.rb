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
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :posts do |t|
  end

  create_table :comments do |t|
    t.integer :post_id
    t.integer :user_id
  end

  create_table :users do |t|
  end
end

class Post < ActiveRecord::Base
  has_many :comments, -> {order(:id)}
  has_many :uniq_users_with_reorder, -> {reorder("").uniq},    :through => :comments, :source => :user
  has_many :uniq_users_with_except,  -> {except(:order).uniq}, :through => :comments, :source => :user
  has_many :uniq_users,              -> {uniq},                :through => :comments, :source => :user
end

class Comment < ActiveRecord::Base
  belongs_to :post
  belongs_to :user
end

class User < ActiveRecord::Base
end

class BugTest < Minitest::Test
  def test_uniq_through_removes_order_to_work_with_postgresql
    post = Post.create!


    # reorder("") should work, i.e. overwrite order from relation
    puts "#" * 90
    puts post.uniq_users_with_reorder.to_sql
    puts "#" * 90
    #refute /ORDER BY/.match(post.uniq_users_with_reorder.to_sql)

    # except(:order) should work, i.e. remove order from relation
    assert(!(post.uniq_users_with_except.to_sql  =~ /order by/i), "generated sql includes ORDER BY")

    # possibly nice to have: uniq() automatically removes order from relation
    assert(!(post.uniq_users.to_sql              =~ /order by/i), "generated sql includes ORDER BY")


  end
end
