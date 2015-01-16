require 'csv'
require 'active_fedora'

namespace :tufts_data do

  desc 'migrate election records'
  task :migrate_election_images, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      puts "Usage: rake tufts_data:fix_election_records['/home/hydradm/path_to/list_of_pids.txt']"
      next
    end

    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        election_record = TuftsBase.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        puts "ERROR Could not locate object: #{pid}"
        next
      end
      if election_record.kind_of?(Array)
        puts "ERROR Multiple results for: #{pid}"
        next
      end

      begin
        ds_opts = {:label => 'Administrative Metadata'}
        new_dca_admin = election_record.create_datastream DcaAdmin, 'DCA-ADMIN', ds_opts
        new_dca_admin.ng_xml = DcaAdmin.xml_template
        new_dca_admin.steward = "dca"
        new_dca_admin.displays = ["elections"]
        new_dca_admin.createdby = "CIDER"

        if election_record.datastreams['DCA-ADMIN'].nil?
          election_record.add_datastream new_dca_admin
        else
          election_record.datastreams['DCA-ADMIN'] = new_dca_admin
        end

        election_record.save!
        #puts "#{pid} successfully migrated"
      rescue => exception
        puts "ERROR There was an error doing the conversion for: #{pid}"
        puts exception.backtrace
        next
      end
    end 
  end
end
