require 'rails_rank/types/date'

module RailsRank
  module DefinedBaseMethods

    # get all time  slot(s).
    #
    # @param date_type  [RailsRank::Types::Date]  delete type.(default=HOURLY)
    # @return [Array<Time>] all time slot(s).
    def all(date_type=RailsRank::Types::Date::HOURLY)
      rails_kvs_driver::session(rails_kvs_driver_config) do |kvs|
        times      = Array.new

        kvs.sorted_sets.each do |key|
          key_a = key.split('-')
          times.push(Time.local(*key_a)) if (date_type == RailsRank::Types::Date::ALL) or key_a.length == date_type
        end

        times
      end
    end

    # delete the data of ranking.
    #
    # @param time       [Time]                    delete time slot.
    # @param date_type  [RailsRank::Types::Date]  delete type.(default=HOURLY)
    def delete(time, date_type=RailsRank::Types::Date::HOURLY)
      rails_kvs_driver::session(rails_kvs_driver_config) do |kvs|
        kvs.delete(key_name(time, date_type))
      end
    end

    # delete all ranking data.
    def delete_all
      rails_kvs_driver::session(rails_kvs_driver_config) do |kvs|
        kvs.delete_all
      end
    end

    # execute the block of code for each ranking.
    #
    # @param key     [String]  key of time slot.
    # @param reverse [Boolean] order desc. [default=asc]
    # @param limit   [Integer] The maximum size of the request at once.
    # @param &block [{|value, score, absolute_position| ...}] block of exec code.
    def each(key, reverse=false, limit=1000, &block)
      rails_kvs_driver::session(rails_kvs_driver_config) {|kvs| kvs.sorted_sets[key].each(reverse, limit, &block) }
    end

    # increment this time slot score of a value. (Time slot is hourly.)
    # @note when doesn't exist the value, set 'score' to value of score.
    #
    # @param value [String]   value to record the score.
    # @param score [Integer]  score to increment
    # @return [Integer] score after increment
    def increment(value, score=1)
      rails_kvs_driver::session(rails_kvs_driver_config) do |kvs|
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
    # @param value [String]   value to record the score.
    # @return [Integer] score
    def score(value)
      rails_kvs_driver::session(rails_kvs_driver_config) do |kvs|
        score = kvs.sorted_sets[key_name(Time.now)][value]
        (score.nil?) ? 0 : score
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

      all(date_type).each do |data_time|
        next unless data_time < base_time

        rails_kvs_driver::session(rails_kvs_driver_config) do |kvs|
          key       = key_name(data_time, date_type)
          total_key = key_name(data_time, date_type - 1)

          # table data of the time slot.
          kvs.sorted_sets[key].each do |member, score, position|
            if RailsRank::Types::Date::YEARLY < date_type
              kvs.sorted_sets[total_key].increment(member, score)
            end
            after_table(date_type, data_time, member, score.to_i, position)
          end

          kvs.sorted_sets.delete(key)
          tabled_data_count += 1
        end
      end

      return tabled_data_count
    end

  end
end