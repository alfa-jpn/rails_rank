namespace :rails_rank do

  desc 'table all the rankings.'

  task :table => :environment do
    # Load all ranking classes.
    Dir.glob('lib/rankings/*.rb').each {|f| require "rankings/#{File.basename(f, '.rb')}" }

    if Object.const_defined?('Rankings')
      Rankings::constants.each do |name|
        object = Rankings::const_get(name)
        next unless object.ancestors.include?(RailsRank::Base)

        puts("#{name} table the ranking...")

        cnt = object.table(RailsRank::Types::Date::HOURLY)
        puts "- tabled #{cnt} hourly data."
        object.table(RailsRank::Types::Date::DAILY)
        puts "- tabled #{cnt} daily data."
        object.table(RailsRank::Types::Date::MONTHLY)
        puts "- tabled #{cnt} monthly data."
        object.table(RailsRank::Types::Date::YEARLY)
        puts "- tabled #{cnt} yearly data."
      end
    end
  end

end