$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'codeclimate-test-reporter'
require 'simplecov'
require 'coveralls'

# Configure Rails Envinronment
ENV['RAILS_ENV'] = 'test'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    CodeClimate::TestReporter::Formatter,
    Coveralls::SimpleCov::Formatter
]

SimpleCov.start
require 'has_reindexable_associations'
require 'minitest/autorun'
