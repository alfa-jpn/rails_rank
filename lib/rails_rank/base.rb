require 'defined_base_methods'

module RailsRank
  # @abstract a class of Ranking is override this class.
  class Base
    extend DefinedBaseMethods

    # return driver class of rails_kvs_driver.
    #
    # @example use rails_kvs_driver-redis_driver
    # def self.rails_kvs_driver
    #   RailsKvsDriver::RedisDriver::Driver
    # end
    #
    # @return [RailsKvsDriver::Base] return driver class of rails_kvs_driver.
    # @abstract override and return driver class of rails_kvs_driver.
    def self.rails_kvs_driver
      raise NoMethodError 'Should override rails_kvs_driver method.'
    end

    # return driver config of rails_kvs_driver.
    #
    # @example
    # def self.rails_kvs_driver_config
    #   {
    #     :host           => 'localhost', # host of KVS.
    #     :port           => 6379,        # port of KVS.
    #     :namespace      => 'Example',   # namespace of avoid a conflict with key
    #     :timeout_sec    => 5,           # timeout seconds.
    #     :pool_size      => 5,           # connection pool size.
    #     :config_key     => :none        # this key is option.(defaults=:none)
    #                                     #  when set this key.
    #                                     #  will refer to a connection-pool based on config_key,
    #                                     #  even if driver setting is the same without this key.
    #   }
    # end
    #
    # @return [Hash] return driver config of rails_kvs_driver.
    # @abstract override and return driver config of rails_kvs_driver.
    def self.rails_kvs_driver_config
      raise NoMethodError 'Should override rails_kvs_driver_config method.'
    end

    # return ranking config.
    #
    # @abstract
    def self.rank_config
      raise NoMethodError 'Should override rank_config method.'
    end
  end
end