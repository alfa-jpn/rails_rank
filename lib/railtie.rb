module RailsRank
  class Railtie < Rails::Railtie
    railtie_name :rails_rank

    rake_tasks do
      Dir[File.join(File.dirname(__FILE__),'tasks/*.rake')].each {|file| load file }
    end
  end
end