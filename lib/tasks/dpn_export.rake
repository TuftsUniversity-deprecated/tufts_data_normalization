require 'csv'
require 'active_fedora'

namespace :tufts_data do

  task :dpn_export, [:arg1] => :environment do |t, args|
    dpn_directory = '/tdr/data05/tufts/dpn'
    dpn_logger = Logger.new('dpn.log')

    if args[:arg1].nil?
      puts 'YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!'
      next
    end

    dry_run = true

    CSV.foreach(args[:arg1], encoding: 'ISO8859-1') do |row|
      pid = row[0]
      begin
        record = TuftsBase.find(pid, cast: true)
      rescue ActiveFedora::ObjectNotFoundError
        dpn_logger.error "ERROR Could not locate object: #{pid}"
        next
      end
      if record.kind_of?(Array)
        dpn_logger.error "ERROR Multiple results for: #{pid}"
        next
      end

      begin
        collection = determine_collection record
        dpn_logger.info "collection: #{collection}"

        next if dry_run

        case record.class.to_s
          when 'TuftsImage'
            process_image record
          else
            dpn_logger.error "#{record.class} for #{pid} unknown"
        end


      rescue => exception
        dpn_logger.error "ERROR There was an error collecting data for: #{pid}"
        dpn_logger.info exception.backtrace
        next
      end
    end
  end

  private

  def process_image record
    if File.file? record.local_path_for 'Archival.tif'
      record.local_path_for 'Archival.tif'
    else
      dpn_logger.error "#{record.class} #{pid} missing Archival.tif datastream file?"
    end
    #out << [pid,record.class,record.steward.first,collection,record.creatordept,(size.to_f / 2**20).round(2)]
  end

  def determine_collection record
    collection = nil
    if record.object_relations[:is_member_of_collection]
      collection = record.object_relations[:is_member_of_collection].first
    elsif record.object_relations[:has_description]
      collection = record.object_relations[:has_description].first
    end

    collection
  end
end
