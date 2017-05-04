begin
  require "bundler/inline"
rescue LoadError => e
  $stderr.puts "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  # Activate the gem you are reporting the issue against.
  gem "activesupport", path: "../rails"
end

require "active_support/core_ext/object/blank"
require "minitest/autorun"
require 'active_support'
# require 'I18n'
require 'i18n/backend/fallbacks'
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

# Ensure backward compatibility with Minitest 4
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

class BugTest < Minitest::Test
  def setup
    # Declare the available locales for my application
    I18n.available_locales = ['en', 'en-FR']
    # Create a fallback on 'en-fr' -> 'en' 
    I18n.fallbacks.map('en-FR': :en)
    # Memoize the fallbacks so we can test their presence.
    I18n.available_locales.map{|x| I18n.fallbacks[x]}
  end

  def test_locale_fallback_setup
    assert_equal I18n.fallbacks, {:en=>[:en], :"en-FR"=>[:"en-FR", :en]}
  end

  def test_i18n_fallbacks_with_inflector
    assert_equal ActiveSupport::Inflector.inflections(:'en-FR'), ActiveSupport::Inflector.inflections(:'en')
  end

  def test_inflector_specific_rules_for_language
    assert_equal 'cats', ActiveSupport::Inflector.pluralize('cat', locale: 'en')
    assert_equal 'cats', ActiveSupport::Inflector.pluralize('cat', locale: :'en-FR')
    assert_equal 'cats', ActiveSupport::Inflector.pluralize('cat', locale: 'en-FR')
  end
end
