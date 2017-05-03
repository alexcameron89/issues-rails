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
  create_table :people, force: true do |t|
    t.string :first_name
  end
  create_table :readers, force: true do |t|
    t.integer :person_id
    t.integer :post_id
  end
  create_table :posts, force: true do |t|
    t.string :title
    t.string :body
  end
end

class Person < ActiveRecord::Base
  has_many :readers
  has_many :posts, through: :readers
end

class Reader < ActiveRecord::Base
  belongs_to :person
  belongs_to :post
end

class Post < ActiveRecord::Base
  has_many :readers
  has_many :people, through: :readers
end

class BugTest < Minitest::Test
  def test_hmt
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    person = Person.new(first_name: "Peter")
    post = Post.new(title: "Cats & Dogs", body: "are pets")

    person.posts << post
    assert person.posts.include?(post)

    person.posts.delete(post)
    refute person.posts.include?(post), "should not contain the post after deletion but did."

    person.save!
    refute person.posts.include?(post)
  end
end
