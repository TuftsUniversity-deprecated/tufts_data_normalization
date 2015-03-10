require 'csv'
require 'active_fedora'

namespace :tufts_data do

  desc 'quick audit of bibliographic citation field'
  task :bibliographic_citation_audit, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      next
    end

    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        record = TuftsBase.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        next
      end
      if record.kind_of?(Array)
        next
      end

      begin

       unless record.bibliographic_citation.empty?
         record.bibliographic_citation.each {|citation| puts "#{pid} has citation: #{citation}"}
       end
       
      rescue => exception
        puts "ERROR There was an error doing the conversion for: #{pid}"
        puts exception.message
        puts exception.backtrace
        next
      end
    end 
  end

  desc 'null out bibliographic citation field'
  task :bibliographic_citation_remove, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      next
    end

    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        record = TuftsBase.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        next
      end
      if record.kind_of?(Array)
        next
      end

      begin

       unless record.bibliographic_citation.empty?
         record.bibliographic_citation = nil
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


  def collection_code(pid)
    pid.sub(/.+:([^.]+).*/, '\1')
  end

  def pid_without_namespace(pid)
    pid.sub(/.+:(.+)$/, '\1')
  end

end
