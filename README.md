# RailsRank

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'rails_rank'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails_rank



## Usage: (using redis_driver)

### Install rails\_kvs\_driver

```ruby
gem "rails_kvs_driver-redis_driver", ">= 0.2.0"
```

### Generate a class of ranking
This code generate access_rank.rb in lib/rankings/ .

```ruby
bundle exec rails g ranking access_rank
```

## Edit generated lib/rankings/access_rank.rb
add driver setting.
```ruby
def self.rails_kvs_driver
  RailsKvsDriver::RedisDriver::Driver
end
```

And override after_table methods.
This method will call after done tabulation.
Specifically,

- after count hourly.(onece an hour)
- after count daily. (onece a day)
- after count monthly.(once a month)
- after count yearly.(once a year)

when table, after_table will be called repeatedly as the number of the data.

You should write a code in here, to insert data to database.

```ruby
# callbacked after table.
# if use data, override this method.
#
# @param date_type [RailsRank::Types::Date] type of tabulation.(HOURLY or DAILY or MONTHLY or YEARLY)
# @param time      [Time]                   time slot of tabulation.
# @param value     [String]                 value of tabulation.
# @param score     [Integer]                score of value.
# @param position  [Integer]                position of value.
def self.after_table(date_type, time, value, score, position)
end
```

For example

when there are the next hourly data.

|value|score|
|:----:|---:|
|'id-1'| 5|
|'id-2'|10|
|'id-3'| 8|


after_table will be called 3 times with the next parameter when table the time slot.

|data_type|time|value|score|position|
|:-------:|:--:|:---:|:---:|:------:|
|RailsRank::Types::Date::HOURLY| data_time|'id-2'|10|0|
|RailsRank::Types::Date::HOURLY| data_time|'id-3'|8|1|
|RailsRank::Types::Date::HOURLY| data_time|'id-1'|5|2|



### Add autoload setting in application.rb
If your application.rb include this setting, don't need this step.

```ruby
config.autoload_paths += %W("#{config.root}/lib")
config.autoload_paths += Dir["#{config.root}/lib/**/"]
```

### Periodical practice
This task must be called every an hour. use cron.
```ruby
bundle exec rake rails_rank:table
```

### How to add and get data.
When add a data of the ranking, or get data before table. use next methods.
```
Rankings::AccessRank.increment(@hoge.id)
Rankings::AccessRank.score(@hoge.id)
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
