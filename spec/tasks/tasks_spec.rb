require 'rspec'
require 'spec_helper'

describe 'tasks' do

  before(:all) do
    # load all rake tasks.
    @rake = Rake::Application.new
    Rake.application = @rake
    Dir.glob('lib/tasks/*.rake') do |file|
      Rake.application.rake_require(File::basename(file, '.rake'), ['lib/tasks'])
    end
    Rake::Task.define_task(:environment)
  end

  it 'exec total' do
    @rake["rails_rank:total"].execute
  end
end