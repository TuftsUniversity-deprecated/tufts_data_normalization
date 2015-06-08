require 'csv'
require 'active_fedora'

namespace :tufts_data do

  desc 'remap 3ds to 4ds'
  task :remap_3ds_records, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      puts "Usage: rake tufts_data:remap_audio_records['/home/hydradm/path_to/list_of_pids.txt']"
      next
    end

    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        record = TuftsImage.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
#        puts "ERROR Could not locate object: #{pid}"
        next
      end
      if record.kind_of?(Array)
#        puts "ERROR Multiple results for: #{pid}"
        next
      end

      begin
        #puts "#{pid}"
        unless record.datastreams['Archival.tif'].nil?
          #if record.datastreams['Archival.tif'].dsLocation.blank?
          #filename = record.local_path_for("Advanced.jpg")
          #dst_path = filename.sub('advanced_jpg','archival_tif')
          #puts "Advanced.jpg: #{filename}"
          #puts "Archival.tif: #{dst_path}"
          #FileUtils.mkdir_p(File.dirname(dst_path))
          #FileUtils.cp(filename, dst_path)
            #puts "#{pid} dsLocation blank"
          #mimeType = record.datastreams['Advanced.jpg'].mimeType
            #puts "#{pid} #{mimeType}"
          #archival_file_url = 'http://bucket01.lib.tufts.edu/' + dst_path.sub('/tdr/','')
          #ds_opts = {:controlGroup => 'E', :mimeType => mimeType, :label => 'Archival Image', :dsLocation => archival_file_url}
          #ds = record.create_datastream(ActiveFedora::Datastream,'Archival.tif', ds_opts)
          #record.add_datastream ds
#puts "#{pid} added archival.tif"
          record.object_relations.add(:has_model,'info:fedora/cm:Image.4DS')
          record.object_relations.delete(:has_model,"info:fedora/cm:Image.3DS")

          #end
        end
          record.save!

      rescue => exception
        puts "ERROR There was an error doing the conversion for: #{pid}"
        puts exception.message
        puts exception.backtrace
        next
      end
    end 
  end

end
