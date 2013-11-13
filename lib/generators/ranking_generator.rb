class RankingGenerator < Rails::Generators::NamedBase

  source_root File.expand_path("../templates", __FILE__)

  desc "This generator creates ranking class file in lib/rankings."

  def create_ranking_file
    template "base.rb.template", "lib/rankings/#{file_name}.rb"
  end
end