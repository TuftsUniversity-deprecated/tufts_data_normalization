require 'csv'
require 'active_fedora'

namespace :tufts_data do

  desc 'migrate perseus records'
  task :migrate_perseus_records, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      puts "Usage: rake tufts_data:migrate_perseus_records['/home/hydradm/path_to/list_of_pids.txt']"
      next
    end

    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        perseus_record = TuftsBase.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        puts "ERROR Could not locate object: #{pid}"
        next
      end
      
      if perseus_record.kind_of?(Array)
        puts "ERROR Multiple results for: #{pid}"
        next
      end

      begin
  	 ds_opts = {:label => 'Descriptive Metadata'}
         new_dca_meta = perseus_record.create_datastream TuftsDcaMeta, 'DCA-META', ds_opts
         perseus_dca_meta = perseus_record.create_datastream TuftsDcaMeta, 'PERSEUS-META', ds_opts
         perseus_dca_meta.ng_xml = << perseus_record.datastreams['DCA-META'].ng_xml
	 new_dca_meta.ng_xml = TuftsDcaMeta.xml_template
         old_dca_meta = perseus_record.datastreams['DCA-META']
         new_dca_meta.title = perseus_record.title
         new_dca_meta.creator = old_dca_meta.creator
         new_dca_meta.source = old_dca_meta.source
         new_dca_meta.description = old_dca_meta.description
         new_dca_meta.date_created = old_dca_meta.date_created
         new_dca_meta.date_available = old_dca_meta.date_available
         new_dca_meta.date_issued = old_dca_meta.date_issued
         new_dca_meta.identifier = old_dca_meta.identifier
         new_dca_meta.rights = old_dca_meta.rights
         new_dca_meta.bibliographic_citation = old_dca_meta.bibliographic_citation
         new_dca_meta.publisher = old_dca_meta.publisher
         new_dca_meta.type = old_dca_meta.type
         new_dca_meta.format = old_dca_meta.format
         new_dca_meta.extent = old_dca_meta.extent
         new_dca_meta.persname = old_dca_meta.persname
         new_dca_meta.corpname = old_dca_meta.corpname
         new_dca_meta.geogname = old_dca_meta.geogname
         new_dca_meta.genre = old_dca_meta.genre
         new_dca_meta.subject = old_dca_meta.subject
         new_dca_meta.funder = old_dca_meta.funder
         new_dca_meta.temporal = old_dca_meta.temporal
         new_dca_meta.resolution = old_dca_meta.resolution 
         new_dca_meta.bitdepth = old_dca_meta.bitdepth
         new_dca_meta.colorspace = old_dca_meta.colorspace
         new_dca_meta.filesize = old_dca_meta.filesize

         if perseus_record.datastreams['DCA-META'].nil?
           perseus_record.add_datastream new_dca_meta
         else
           perseus_record.datastreams['DCA-META'] = new_dca_meta
           perseus_record.add_datastream perseus_dca_meta
#           perseus_recordstreams['PERSEUS-META'] = old_dca_meta
         end

         ds_opts = {:label => 'Administrative Metadata'}

         new_dca_admin = perseus_record.create_datastream DcaAdmin, 'DCA-ADMIN', ds_opts
         new_dca_admin.ng_xml = DcaAdmin.xml_template
         new_dca_admin.displays = ["nowhere"]

         if perseus_record.datastreams['DCA-ADMIN'].nil?
           perseus_record.add_datastream new_dca_admin
         else
           perseus_record.datastreams['DCA-ADMIN'] = new_dca_admin
         end
         perseus_record.save!

      rescue => ex
        puts "ERROR There was an error doing the conversion for: #{pid}"
 puts ex.message
  puts ex.backtrace.join("\n")
        next
      end
    end 
  end
end
