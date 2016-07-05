require 'active_fedora'

namespace :tufts_data do
  desc 'Batch revert published to drafts.'
  task :batch_revert_drafts => :environment do |t|
    if !File.exist?("config/solr.yml")
      puts "No solr configuration! Put it in solr.yml!"
      next
    end

    creds = YAML.load_file("config/solr.yml")
    solr = RSolr.connect :url => creds[Rails.env]['url']
    response = solr.get 'select', :params => {
      :q => "id:#{PidUtils.published_namespace}*",
      :fl => "id, title_tesim",
      :rows => 9999999
    }

      response['response']['docs'].each do |record|
        puts
        puts "Reverting #{record['title_tesim']} (#{record['id']})."
        tb = TuftsBase.find(record['id'])
        begin
          RevertService.new(tb).run
        rescue NoMethodError => boom
          puts "Error reverting! : #{boom.inspect}"
        end
      end

  end # End task batch_revert_drafts
end # End namespace tufts_data

