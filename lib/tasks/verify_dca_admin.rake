require 'csv'
require 'active_fedora'

namespace :tufts_data do

  desc 'migrate generic /easy dca records that display in dl, have createdby cider, steward dca'
  task :verify_dca_admin, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      next
    end
    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        object = TuftsBase.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        puts "ERROR Could not locate object: #{pid}"
        next
      end
      if object.kind_of?(Array)
        puts "ERROR Multiple results for: #{pid}"
        next
      end

      begin
         datastream_content = object.datastreams['DCA-ADMIN'].ng_xml.to_s
         unless datastream_content[/<admin xmlns:local="http:\/\/nils.lib.tufts.edu\/dcaadmin\/" xmlns:ac="http:\/\/purl.org\/dc\/dcmitype\/">/] || datastream_content[/<admin xmlns:ac="http:\/\/purl.org\/dc\/dcmitype\/" xmlns:local="http:\/\/nils.lib.tufts.edu\/dcaadmin\/">/]
           puts "#{pid} needs updating"
         end 
      rescue => exception
        puts "ERROR There was an error doing the conversion for: #{pid}"
        puts exception.backtrace
        next
      end
    end 
  end
end
