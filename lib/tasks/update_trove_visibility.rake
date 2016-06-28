require 'rsolr'
require 'yaml'

namespace :tufts_data do
  desc 'Update trove visibility settings'
  task :update_trove_visibility => :environment do |t|
    if !File.exist?("config/solr.yml")
      puts "No solr configuration! Put it in solr.yml!"
      next
    end

    creds = YAML.load_file("config/solr.yml")
    solr_url = creds['development']['url']

    solr = RSolr.connect :url => solr_url
    response = solr.get 'select', :params => {:q => '*:*'}

    trove_ids = []
    response['response']['docs'].each do |myrecord|
      if myrecord['displays_ssi'] == "trove"
        trove_ids.push myrecord['id']
      end
    end

    puts trove_ids
  end
end

