require 'csv'
require 'active_fedora'
require 'fileutils'
require 'open-uri'
require 'uri'



namespace :tufts_data do

  @dpn_logger = Logger.new('dpn.log')
  task :oai_status_check, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts 'YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!'
      next
    end

    dry_run = false

    CSV.foreach(args[:arg1], encoding: 'ISO8859-1') do |row|
      pid = row[0]
      begin
        record = TuftsBase.find(pid, cast: true)
        puts("#{pid} , #{record.state}")
      rescue ActiveFedora::ObjectNotFoundError
        @dpn_logger.error "ERROR Could not locate object: #{pid}"
        next
      end
    end
  end

  task :oai_date_remap, [:arg1] => :environment do |t, args|


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
        published_pid = pid.gsub("draft:","tufts:")
        published_record = TuftsBase.find(published_pid, cast: true)
        record = TuftsBase.find(pid, cast: true)
#        actual_date_created = record.inner_object.profile["objCreateDate"]
        original_date_created = published_record.date_created
puts "#{original_date_created}"
        record.date = original_date_created
        record.save!

      rescue => exception
        @dpn_logger.error "ERROR There was an error collecting data for: #{pid}"
        puts exception
        puts exception.backtrace
        next
      end
    end
  end
end
