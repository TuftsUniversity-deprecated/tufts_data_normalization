require 'rsolr'
require 'yaml'
require 'active-fedora'

namespace :tufts_data do
  desc 'Update trove visibility settings'
  task :update_trove_visibility => :environment do |t|
    if !File.exist?("config/solr.yml")
      puts "No solr configuration! Put it in solr.yml!"
      next
    end

    creds = YAML.load_file("config/solr.yml")
    solr = RSolr.connect :url => creds[Rails.env]['url']
    response = solr.get 'select', :params => {:q => 'displays_ssi:trove'}

    trove_ids = []
    response['response']['docs'].each do |myrecord|
      trove_ids.push myrecord['id']
    end

    puts trove_ids
  end
end

