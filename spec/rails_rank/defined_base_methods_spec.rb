require 'rspec'
require 'spec_helper'
require 'rails_rank/defined_base_methods'



describe RailsRank::DefinedBaseMethods do

  before(:each) do
    @driver = RailsKvsDriver::RedisDriver::Driver
    @driver_config = {
        :host           => 'localhost',         # host of KVS.
        :port           => 6379,                # port of KVS.
        :namespace      => 'Spec::RailsRank',   # namespace of avoid a conflict with key
        :timeout_sec    => 5,                   # timeout seconds.
        :pool_size      => 5,                   # connection pool size.
        :config_key     => :none                # this key is option.(defaults=:none)
                                                #  when set this key.
                                                #  will refer to a connection-pool based on config_key,
                                                #  even if driver setting is the same without this key.
    }

    @defined_base_methods = RailsRank::DefinedBaseMethods.new
    @defined_base_methods.stub({ rails_kvs_driver: @driver, rails_kvs_driver_config: @driver_config })

    Time.stub({ now: Time.local(2013,11,5) })

    @driver::session(@driver_config) {|kvs| kvs.delete_all }
  end

  after(:each) do
    @driver::session(@driver_config) {|kvs| kvs.delete_all }
  end

  context 'when call all,' do
    before(:each) do
      (0 .. 11).each do |i|
        Time.stub({ now: Time.local(2013,11,5, i) })
        @defined_base_methods.increment("NyarukoSan", 2865)
      end
      @times = @defined_base_methods.all
    end

    it 'return times' do
      expect(@times[0].instance_of?(Time)).to be_true

    end

    it 'return correct length' do
      expect(@times.length).to eq(12)
    end
  end

  context 'when call delete' do
    before(:each) do
      @defined_base_methods.increment('NyarukoSan',2865)
    end

    it 'delete ranking data.' do
      @driver::session(@driver_config) do |kvs|
        expect{
          @defined_base_methods.delete(Time.now)
        }.to change{
          kvs.sorted_sets.length
        }.by(-1)
      end
    end
  end

  context 'when call count,' do
    before(:each) do
      @defined_base_methods.increment('NyarukoSan',2865)
    end

    it 'return score of value' do
      expect(@defined_base_methods.count('NyarukoSan')).to eq(2865)
    end

    it 'nothing value, return 0' do
      expect(@defined_base_methods.count('Nothing value')).to eq(0)
    end
  end

  context 'when call delete' do
    before(:each) do
      @defined_base_methods.increment('NyarukoSan',2865)
    end

    it 'delete ranking data.' do
      @driver::session(@driver_config) do |kvs|
        expect{
          @defined_base_methods.delete(Time.now)
        }.to change{
          kvs.sorted_sets.length
        }.by(-1)
      end
    end
  end

  context 'when call delete_all' do
    before(:each) do
      (0 .. 23).each do |i|
        Time.stub({ now: Time.local(2013,11,5, i) })
        @defined_base_methods.increment("NyarukoSan", 2865)
      end
    end

    it 'delete ranking data.' do
      @driver::session(@driver_config) do |kvs|
        expect{
          @defined_base_methods.delete_all
        }.to change{
          kvs.sorted_sets.length
        }.by(-24)
      end
    end
  end

  context 'when call increment,' do
    before(:each) do
      @key = @defined_base_methods.key_name(Time.now)
      @defined_base_methods.increment('NyarukoSan',2865)
    end

    it 'create sorted_set, and set score' do
      @driver::session(@driver_config) do |kvs|
        expect(kvs.sorted_sets.length).to eq(1)
        expect(kvs.sorted_sets[@key, 'NyarukoSan']).to eq(2865)
      end
    end

    it 'increment score of value' do
      @driver::session(@driver_config) do |kvs|
        expect{
          @defined_base_methods.increment('NyarukoSan')
        }.to change{
          kvs.sorted_sets[@key, 'NyarukoSan']
        }.by(1)
      end
    end
  end

  context 'when call key_name' do
    it 'return correct key.' do
      expect(@defined_base_methods.key_name(Time.now)).to eq('2013-11-05-00')
      expect(@defined_base_methods.key_name(Time.now, RailsRank::Types::Date::DAILY)).to eq('2013-11-05')
      expect(@defined_base_methods.key_name(Time.now, RailsRank::Types::Date::MONTHLY)).to eq('2013-11')
    end
  end

end