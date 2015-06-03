require 'csv'
require 'active_fedora'

namespace :tufts_data do

  desc 'clean up STREAM_ATOM and PRESENT_SMIL on audio objects'
  task :clean_up_audio_datastreams, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      puts "Usage: rake tufts_data:fix_election_records['/home/hydradm/path_to/list_of_pids.txt']"
      next
    end

    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        record = TuftsBase.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        puts "ERROR Could not locate object: #{pid}"
        next
      end
      if record.kind_of?(Array)
        puts "ERROR Multiple results for: #{pid}"
        next
      end

      begin

       unless record.datastreams['ARCHIVAL_SOUND'].nil? 
#          puts "#{pid} has ARCHIVAL_SOUND"
          filename = record.local_path_for("ARCHIVAL_SOUND")
          dst_path = filename.sub('archival_sound','archival_wav')
#          puts "ARCHIVAL SOUND: #{filename}"
#          puts "ARCHIVAL_WAV: #{dst_path}"
#          FileUtils.mkdir_p(File.dirname(dst_path))
#          FileUtils.cp(filename, dst_path)
           archival_audio_file_url = 'http://bucket01.lib.tufts.edu/' + dst_path.sub('/tdr/','')
           ds_opts = {:controlGroup => 'E', :mimeType => 'text/xml', :label => 'Archival Audio Data', :dsLocation => archival_audio_file_url}

           ds = record.create_datastream(ActiveFedora::Datastream,'ARCHIVAL_WAV', ds_opts)
#puts "#{archival_audio_file_url}"
           record.add_datastream ds
        end
#       end
       #unless record.datastreams['STREAM_ATOM'].nil? 
          #puts "#{pid} has STREAM_ATOM"
          #doc = record.datastreams["STREAM_ATOM"].content
  	  #dest_folder = '/home/hydradm/tufts/stream_atom_archiving/'
          #local_filename = dest_folder + pid + '_stream_atom.xml'
          #File.open(local_filename, 'w') {|f| f.write(doc) }
          #record.datastreams['STREAM_ATOM'].delete
       #end
       
       #unless  record.datastreams['PRESENT_SMIL'].nil?
          #puts "#{pid} has PRESENT_SMIL"
          #filename = record.local_path_for("PRESENT_SMIL")
  	  #dest_folder = '/home/hydradm/tufts/present_smil_archiving/'
          #FileUtils.cp(filename, dest_folder) 
          #filename = record.local_path_for("PRESENT_SMIL")
          #FileUtils.rm(filename)
          #puts "removing #{filename}"
          #dir = File.dirname(filename)
          #if (Dir.entries(dir) - %w{ . .. }).empty?
          #  FileUtils.remove_dir(dir)
          #  puts "removing directory #{dir}"
          #else
          #  puts "directory not empty #{dir}"
          #end
          #record.datastreams['PRESENT_SMIL'].delete
       #end
#
      record.save!

      rescue => exception
        puts "ERROR There was an error doing the conversion for: #{pid}"
        puts exception.message
        puts exception.backtrace
        next
      end
    end 
  end

  def collection_code(pid)
    pid.sub(/.+:([^.]+).*/, '\1')
  end

  def pid_without_namespace(pid)
    pid.sub(/.+:(.+)$/, '\1')
  end

end
