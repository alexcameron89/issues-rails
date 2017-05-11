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

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :email
  end

  create_table :user_settings do |t|
    t.integer :user_id
    t.string :favourite_color
  end
end

class User < ActiveRecord::Base
  has_one :user_setting
  accepts_nested_attributes_for :user_setting
  validates_presence_of :email
end

class UserSetting < ActiveRecord::Base
  belongs_to :user
end

class BugTest < Minitest::Test
  def test_update_without_transaction
    user = User.create!(email: 'godfrey@example.com', user_setting_attributes: {favourite_color: 'orange'})
    assert_equal 'orange', user.user_setting.favourite_color

    assert ! user.update(email: nil, user_setting_attributes: {favourite_color: 'red'})

    user.reload

    assert user.user_setting.present?
    assert_equal 'orange', user.user_setting.favourite_color
  end

  def test_update_with_transaction
    user = User.create!(email: 'godfrey@example.com', user_setting_attributes: {favourite_color: 'orange'})
    assert_equal 'orange', user.user_setting.favourite_color

    User.transaction do
      assert ! user.update(email: nil, user_setting_attributes: {favourite_color: 'red'})
    end

    user.reload

    assert user.user_setting.present?
    assert_equal 'orange', user.user_setting.favourite_color
  end

  def test_update_without_transaction!
    user = User.create!(email: 'godfrey@example.com', user_setting_attributes: {favourite_color: 'orange'})
    assert_equal 'orange', user.user_setting.favourite_color

    assert_raises(ActiveRecord::RecordInvalid) do
      user.update!(email: nil, user_setting_attributes: {favourite_color: 'red'})
    end

    user.reload

    assert user.user_setting.present?
    assert_equal 'orange', user.user_setting.favourite_color
  end

  def test_update_with_transaction!
    user = User.create!(email: 'godfrey@example.com', user_setting_attributes: {favourite_color: 'orange'})
    assert_equal 'orange', user.user_setting.favourite_color

    assert_raises(ActiveRecord::RecordInvalid) do
      User.transaction do
        assert ! user.update!(email: nil, user_setting_attributes: {favourite_color: 'red'})
      end
    end

    user.reload

    assert user.user_setting.present?
    assert_equal 'orange', user.user_setting.favourite_color
  end
end
