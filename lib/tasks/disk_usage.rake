require 'csv'
require 'active_fedora'

namespace :tufts_data do

  task :disk_usage_report, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      next
    end
    out = CSV.open("file.csv", "a+")
    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        record = TuftsBase.find(pid, cast: true)
      rescue ActiveFedora::ObjectNotFoundError
        puts "ERROR Could not locate object: #{pid}"
        next
      end
      if record.kind_of?(Array)
        puts "ERROR Multiple results for: #{pid}"
        next
      end

      begin
        collection = nil
        if record.object_relations[:is_member_of_collection] 
          collection = record.object_relations[:is_member_of_collection].first
        elsif record.object_relations[:has_description] 
          collection = record.object_relations[:has_description].first
        end
        size = 0
        case record.class.to_s
          when "TuftsPdf"
            size = File.size record.local_path_for 'Archival.pdf' if File.file? record.local_path_for 'Archival.pdf'
            out << [pid,record.class,record.steward.first,collection,record.creatordept,(size.to_f / 2**20).round(2)]
          when "TuftsEAD", "TuftsTEI"
            size = File.size record.local_path_for 'Archival.pdf' if File.file? record.local_path_for 'Archival.pdf'
            out << [pid,record.class,record.steward.first,collection,record.creatordept,size.to_f]
          when "TuftsAudio"
            audio_size = 0
            audio_size = File.size record.local_path_for 'ARCHIVAL_WAV' if File.file? record.local_path_for 'ARCHIVAL_WAV'
            xml_size = 0
            xml_size = File.size record.local_path_for 'ARCHIVAL_XML' if File.file? record.local_path_for 'ARCHIVAL_XML'
            size = xml_size + audio_size
            out << [pid,record.class,record.steward.first,collection,record.creatordept,(size.to_f / 2**20).round(2)]
#          when "TuftsGenericObject"
#            size = File.size record.local_path_for 'GENERIC-CONTENT'
#            out << [pid,record.class,record.steward.first,(size.to_f / 2**20).round(2)]
          when 'TuftsImage'
            size = File.size record.local_path_for 'Archival.tif' if File.file? record.local_path_for 'Archival.tif'
            out << [pid,record.class,record.steward.first,collection,record.creatordept,(size.to_f / 2**20).round(2)]
          when 'TuftsRCR'
            size = File.size record.local_path_for 'RCR-CONTENT' if File.file? record.local_path_for 'RCR-CONTENT'
            out << [pid,record.class,record.steward.first,collection,record.creatordept,size.to_f]
          when 'TuftsVideo'
            video_size = 0
            xml_size = 0
            video_size = File.size record.local_path_for 'Archival.video' if File.file? record.local_path_for 'Archival.video'
            xml_size = File.size record.local_path_for 'ARCHIVAL_XML' if File.file? record.local_path_for 'ARCHIVAL_XML'
            size = video_size + xml_size
            out << [pid,record.class,record.steward.first,collection,record.creatordept,(size.to_f / 2**20).round(2)]
          when 'TuftsVotingRecord'
            size = File.size record.local_path_for 'RECORD-XML' if File.file? record.local_path_for 'RECORD-XML'
            out << [pid,record.class,record.steward.first,collection,record.creatordept,size.to_f]
          else
            puts "#{record.class} for #{pid} unknown"
          end
          
      rescue => exception
        puts "ERROR There was an error collecting data for: #{pid}"
        puts exception.backtrace
        next
      end
    end 
  end
end
