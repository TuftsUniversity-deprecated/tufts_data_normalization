require 'active_fedora'
require 'yaml'

namespace :tufts_data do
  @solr = ""

  desc 'List all fields, and their usage stats'
  task :audit_fields => :environment do |t|
    getAllFields.each do |field|
      results = getSolr.get(
        'select',
        :params => {
          :q => "#{field}:[* TO *]",
          :rows => 0
      })
      puts "#{field}: #{results['response']['numFound']}"
    end
  end

  def getSolr
    if(String === @solr)
      creds = YAML.load_file("config/solr.yml")
      @solr = RSolr.connect(:url => creds[Rails.env]['url'])
    else
      @solr
    end
  end

  def getAllFields
    getSolr.get(
      'select',
      :params => {
        :q => '*:*',
        :rows => 0,
        :wt => 'csv'
      }
    ).split(",")
  end

end

