require 'rr'
require 'test/unit'
require 'test/unit/rr'
require 'fileutils'
require 'fluent/log'
require 'fluent/test'
require 'fluent/test/driver/filter'
require 'fluent/test/helpers'
require 'webmock/test_unit'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "test/fixtures/cassettes"
  config.hook_into :webmock
end
