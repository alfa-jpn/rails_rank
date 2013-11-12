require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'rails_rank'
require 'rails_kvs_driver/redis_driver'

RSpec.configure do |config|
  config.mock_framework = :rspec
end