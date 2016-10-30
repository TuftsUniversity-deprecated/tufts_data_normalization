require 'csv'
require 'active_fedora'
require 'fileutils'


namespace :tufts_data do

  @dpn_logger = Logger.new('dpn.log')

  task :dpn_export, [:arg1] => :environment do |t, args|


    if args[:arg1].nil?
      puts 'YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!'
      next
    end

    dry_run = false

    CSV.foreach(args[:arg1], encoding: 'ISO8859-1') do |row|
      pid = row[0]
      begin
        record = TuftsBase.find(pid, cast: true)
      rescue ActiveFedora::ObjectNotFoundError
        @dpn_logger.error "ERROR Could not locate object: #{pid}"
        next
      end
      if record.kind_of?(Array)
        @dpn_logger.error "ERROR Multiple results for: #{pid}"
        next
      end

      begin
        collection = determine_collection record
        @dpn_logger.info "collection: #{collection}"

        next if dry_run

        case record.class.to_s
          when 'TuftsImage'
            process_image(record, collection)
          else
            @dpn_logger.error "#{record.class} for #{pid} unknown"
        end


      rescue => exception
        @dpn_logger.error "ERROR There was an error collecting data for: #{pid}"
        puts exception
        puts exception.backtrace
        next
      end
    end
  end

  private

  def process_image(record, collection)
    if File.file? record.local_path_for 'Archival.tif'
      source_file = record.local_path_for('Archival.tif')
      export_file(source_file, collection)
    else
      @dpn_logger.error "#{record.class} #{pid} missing Archival.tif datastream file?"
    end

  end

  def export_file(file, collection)
    dpn_directory = '/tdr/data05/tufts/dpn'
    base_name = File.basename file
    dest = "#{dpn_directory}/#{collection}/#{base_name}"
    copy_with_path(file, dest)
  end

  def copy_with_path(src, dst)
    FileUtils.mkdir_p(File.dirname(dst))
    if File.file?(dst)
      @dpn_logger.error "#{dst} already exists"
    else
      FileUtils.cp(src, dst)
    end
  end

  def determine_collection record
    collection = ''
    if record.object_relations[:is_member_of_collection]
      collection = record.object_relations[:is_member_of_collection].first
    elsif record.object_relations[:has_description]
      collection = record.object_relations[:has_description].first
    end

    collection.slice!('info:fedora/')

    if collection.nil? || collection == ''
      collection = record.source
    end

    if collection.nil? || collection.length < 2 || collection.length > 40
      collection = 'uncollected'
    end

    collection
  end
end
