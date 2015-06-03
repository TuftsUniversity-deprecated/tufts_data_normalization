require 'csv'
require 'active_fedora'

namespace :tufts_data do

  desc 'remap audio text to audio'
  task :remap_audio_records, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      puts "Usage: rake tufts_data:remap_audio_records['/home/hydradm/path_to/list_of_pids.txt']"
      next
    end

    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        record = TuftsAudio.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
#        puts "ERROR Could not locate object: #{pid}"
        next
      end
      if record.kind_of?(Array)
#        puts "ERROR Multiple results for: #{pid}"
        next
      end

      begin

          record.object_relations.add(:has_model,'info:fedora/cm:Audio')
          record.object_relations.delete(:has_model,"info:fedora/cm:Audio.OralHistory")
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
