require 'csv'
require 'active_fedora'

namespace :tufts_data do

  desc 'unpublish_drafts'
  task :unpublish_drafts, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      puts "Usage: rake tufts_data:unpublish_drafts['/home/hydradm/path_to/list_of_pids.txt']"
      next
    end

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
        draft_object = TuftsBase.find(pid, cast: true)
        draft_object.unpublishing = true
        draft_object.published_at = nil
        draft_object.save

      rescue Rubydora::FedoraInvalidRequest => fir
        puts "Invalid Fedora Request #{pid}"
      rescue => exception
        puts "ERROR There was an error doing the conversion for: #{pid}"
        puts exception.message
        puts exception.backtrace
        puts exception.class
        next
      end
    end 
  end


end
