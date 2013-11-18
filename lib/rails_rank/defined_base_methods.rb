require 'rails_rank/types/date'

module RailsRank
  module DefinedBaseMethods

    # get all time slot(s).
    #
    # @param date_type  [RailsRank::Types::Date] delete type.(default=HOURLY)
    # @param session    [RailsKvsDriver::Base]   default is nil. if there's session instance, set it.
    # @return [Array<Time>] all time slot(s).
    def all(date_type=RailsRank::Types::Date::HOURLY, session=nil)
      start_kvs_session(session) do |kvs|
        times   = Array.new
        all_key = (date_type == RailsRank::Types::Date::ALL)

        kvs.sorted_sets.each do |key|
          key_a = key.split('-')
          times.push(Time.local(*key_a)) if all_key or key_a.length == date_type
        end

        times
      end
    end

    # delete the data of ranking.
    #
    # @param time       [Time]                    delete time slot.
    # @param date_type  [RailsRank::Types::Date]  delete type.(default=HOURLY)
    # @param session    [RailsKvsDriver::Base]    default is nil. if there's session instance, set it.
    def delete(time, date_type=RailsRank::Types::Date::HOURLY, session=nil)
      start_kvs_session(session) do |kvs|
        kvs.delete(key_name(time, date_type))
      end
    end

    # delete all ranking data.
    # @param session [RailsKvsDriver::Base] default is nil. if there's session instance, set it.
    def delete_all(session=nil)
      start_kvs_session(session) do |kvs|
        kvs.delete_all
      end
    end

    # execute the block of code for each ranking.
    #
    # @param key     [String]               key of time slot.
    # @param reverse [Boolean]              order desc. [default=asc]
    # @param limit   [Integer]              The maximum size of the request at once.
    # @param session [RailsKvsDriver::Base] default is nil. if there's session instance, set it.
    # @param &block  [{|value, score, absolute_position| ...}] block of exec code.
    def each(key, reverse=false, limit=1000, session=nil, &block)
      start_kvs_session(session) {|kvs| kvs.sorted_sets[key].each(reverse, limit, &block) }
    end

    # increment this time slot score of a value. (Time slot is hourly.)
    # @note when doesn't exist the value, set 'score' to value of score.
    #
    # @param value   [String]               value to record the score.
    # @param score   [Integer]              score to increment.
    # @param session [RailsKvsDriver::Base] default is nil. if there's session instance, set it.
    # @return [Integer] score after increment
    def increment(value, score=1, session=nil)
      start_kvs_session(session) do |kvs|
        kvs.sorted_sets[key_name(Time.now)].increment(value, score).to_i
      end
    end

    # get ranking key of a time slot.
    #
    # @param time      [Time]                   time of key.
    # @param date_type [RailsRank::Types::Date] type of key.(default=HOURLY)
    # @return [String] key name.
    def key_name(time, date_type=RailsRank::Types::Date::HOURLY)
      case date_type
        when RailsRank::Types::Date::YEARLY
          time.strftime('%Y')
        when RailsRank::Types::Date::MONTHLY
          time.strftime('%Y-%m')
        when RailsRank::Types::Date::DAILY
          time.strftime('%Y-%m-%d')
        else
          time.strftime('%Y-%m-%d-%H')
      end
    end

    # get this time slot score of a value.(Time slot is hourly.)
    # @note when doesn't exist the value, return 0.
    #
    # @param value   [String]               value to record the score.
    # @param session [RailsKvsDriver::Base] default is nil. if there's session instance, set it.
    # @return [Integer] score
    def score(value, session=nil)
      start_kvs_session(session) do |kvs|
        score = kvs.sorted_sets[key_name(Time.now)][value]
        (score.nil?) ? 0 : score.to_i
      end
    end

    # table score.
    # this methods total the calculations done data.
    #
    # @param date_type [RailsRank::Types::Date] type of tabulation.
    # @return [Integer] count tabled data.
    def table(date_type)
      raise ArgumentError if date_type < RailsRank::Types::Date::YEARLY

      tabled_data_count = 0
      base_time = Time.local(*(Time.now.to_a.reverse[4..(3+date_type)]))

      start_kvs_session do |kvs|
        all(date_type).each do |data_time|
          next unless data_time < base_time

          key       = key_name(data_time, date_type)
          total_key = key_name(data_time, date_type - 1)

          each(key, false, 1000, kvs) do |member, score, position|
            if RailsRank::Types::Date::YEARLY < date_type
              kvs.sorted_sets[total_key].increment(member, score)
            end
            after_table(date_type, data_time, member, score.to_i, position)
          end

          delete(data_time, date_type, kvs)
          tabled_data_count += 1
        end
      end
      after_table_all(date_type, base_time)
      return tabled_data_count
    end


    private
    # start key-value store session.
    # if session of params isn't nil, call &block with this session.
    #
    # @params session [RailsKvsDriver::Base] session.
    # @params yield   [block] exec block with session.
    # @return [Object] Evaluation of the block.
    def start_kvs_session(session=nil)
      if session.nil?
        rails_kvs_driver::session(rails_kvs_driver_config) {|new_session| yield new_session }
      else
        yield session
      end
    end

  end
end