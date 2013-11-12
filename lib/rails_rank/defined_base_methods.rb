require 'rails_rank/types/date'

module RailsRank
  class DefinedBaseMethods

    # get all time  slot(s).
    #
    # @param date_type  [RailsRank::Types::Date]  delete type.(default=HOURLY)
    # @return [Array<Time>] all time slot(s).
    def all(date_type=RailsRank::Types::Date::HOURLY)
      rails_kvs_driver::session(rails_kvs_driver_config) do |kvs|
        times      = Array.new
        key_length = (date_type == RailsRank::Types::Date::ALL) ? nil : date_type + 1

        kvs.sorted_sets.each do |key|
          key_a = key.split('-')
          times.push(Time.local(*key_a)) if key_length == nil or key_a.length == key_length
        end

        times
      end
    end

    # count this time slot score of a value.(Time slot is hourly.)
    # @note when doesn't exist the value, return 0.
    #
    # @param value [String]   value to record the score.
    # @return [Integer] score
    def count(value)
      rails_kvs_driver::session(rails_kvs_driver_config) do |kvs|
        count = kvs.sorted_sets[key_name(Time.now), value]
        (count.nil?) ? 0 : count
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

    # increment this time slot score of a value. (Time slot is hourly.)
    # @note when doesn't exist the value, set 'score' to value of score.
    #
    # @param value [String]   value to record the score.
    # @param score [Integer]  score to increment
    # @return [Integer] score after increment
    def increment(value, score=1)
      rails_kvs_driver::session(rails_kvs_driver_config) do |kvs|
        kvs.sorted_sets.increment(key_name(Time.now), value, score).to_i
      end
    end

    # get ranking key of a time slot.
    #
    # @param time      [Time]                   time of key.
    # @param date_type [RailsRank::Types::Date] type of key.(default=HOURLY)
    # @return [String] key name.
    def key_name(time, date_type=RailsRank::Types::Date::HOURLY)
      case date_type
        when RailsRank::Types::Date::MONTHLY
          time.strftime('%Y-%m')
        when RailsRank::Types::Date::DAILY
          time.strftime('%Y-%m-%d')
        else
          time.strftime('%Y-%m-%d-%H')
      end
    end

  end
end