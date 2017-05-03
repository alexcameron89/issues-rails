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

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :users, force: true  do |t|
    t.string :type
  end

  create_table :profiles, force: true  do |t|
    t.integer :user_id
  end
end

class User < ActiveRecord::Base
end

class AdminUser < User
  has_one :profile, foreign_key: :user_id, inverse_of: :user
end

class Profile < ActiveRecord::Base
  belongs_to :user, inverse_of: :profile, class_name: 'AdminUser'
  after_create :do_some_post_processing

  cattr_accessor :instance_for_testing

  def do_some_post_processing
    self.class.instance_for_testing = self.user.profile
  end
end

class BugTest < Minitest::Test
  def test_inverse_associations
    user = AdminUser.create!
    user.profile = Profile.new
    assert_equal user.profile, Profile.instance_for_testing
  end
end
