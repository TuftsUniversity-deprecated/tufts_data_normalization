require 'csv'
require 'active_fedora'

namespace :tufts_data do

  task :election_record_xml_export, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
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
        base_directory = '/tdr/data05/tufts/central/dca'
        #base_directory = '/home/hydradm/test_election_export'
        record_xml_dir = 'record-xml'
        export_file_dir= base_directory + '/' + collection_code(pid) + '/' + record_xml_dir + '/'
        #puts "#{export_file_dir}"

        FileUtils.mkdir_p(export_file_dir)
        export_file = export_file_dir + pid_without_namespace(pid) + '.xml'
        #puts "#{export_file}"
        File.open(export_file, 'w:ISO-8859-1') { |file|
          file.write(record.datastreams["RECORD-XML"].content.force_encoding("ISO-8859-1"))
        }
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
