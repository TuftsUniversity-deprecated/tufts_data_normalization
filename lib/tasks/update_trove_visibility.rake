require 'rsolr'
require 'yaml'
require 'active_fedora'

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

    trove_ids.each do |pid|
      begin
        fedora_object = TuftsBase.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        puts "ERROR Could not locate object: #{pid}"
        next
      end

      if fedora_object.kind_of?(Array)
        puts "ERROR Multiple results for: #{pid}"
        next
      end

      begin
        if fedora_object.visibility.nil?
          puts "Visibility is nil"
        else
          puts "#{fedora_object.visibility}"
        end
      rescue => ex
        puts "ERROR There was an error doing the conversion for: #{pid}"
        puts ex.message
        puts ex.backtrace.join("\n")
        next
      end # End print title
    end # End trove_ids.each
  end # End task update_trove_visibility
end # End namespace tufts_data

