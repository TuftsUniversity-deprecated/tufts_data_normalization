require 'csv'
require 'active_fedora'

namespace :tufts_data do

  desc 'migrate generic /easy dca records that display in dl, have createdby cider, steward dca'
  task :generic_dca_dl_normalization, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      next
    end
    SLEEP_TIME=1.0/2.0
    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
    sleep(SLEEP_TIME)
      pid = row[0]
      begin
        aah_record = TuftsBase.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        puts "ERROR Could not locate object: #{pid}"
        next
      end
      if aah_record.kind_of?(Array)
        puts "ERROR Multiple results for: #{pid}"
        next
      end

      begin
        ds_opts = {:label => 'Administrative Metadata'}
        new_dca_admin = aah_record.create_datastream DcaAdmin, 'DCA-ADMIN', ds_opts
        new_dca_admin.ng_xml = DcaAdmin.xml_template
        new_dca_admin.steward = "dca"
        new_dca_admin.createdby = "CIDER"
        new_dca_admin.displays = ["dl"]

        if aah_record.datastreams['DCA-ADMIN'].nil?
          aah_record.add_datastream new_dca_admin
        else
          aah_record.datastreams['DCA-ADMIN'] = new_dca_admin
        end

        aah_record.save!

      rescue => exception
        puts "ERROR There was an error doing the conversion for: #{pid}"
        puts exception.backtrace
        next
      end
    end 
  end
end
