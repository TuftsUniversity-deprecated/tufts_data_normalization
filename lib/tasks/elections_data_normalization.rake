require 'csv'
require 'active_fedora'

namespace :tufts_data do

  desc 'migrate election records'
  task :fix_election_records, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      puts "Usage: rake tufts_data:fix_election_records['/home/hydradm/path_to/list_of_pids.txt']"
      next
    end

    CSV.foreach(args[:arg1], encoding: "ISO8859-1") do |row|
      pid = row[0]
      begin
        election_record = TuftsVotingRecord.find(pid)
      rescue ActiveFedora::ObjectNotFoundError
        puts "ERROR Could not locate object: #{pid}"
        next
      end
      if election_record.kind_of?(Array)
        puts "ERROR Multiple results for: #{pid}"
        next
      end

      begin
       base_directory = 'http://bucket01.lib.tufts.edu/data05/tufts/central/dca'
       record_xml_dir = 'record-xml'
       nnv_file_url= base_directory + '/' + collection_code(pid) + '/' + record_xml_dir + '/' + pid_without_namespace(pid) + '.xml'
       ds_opts = {:controlGroup => 'E', :mimeType => 'text/xml', :label => 'Voting Record XML Data', :dsLocation => nnv_file_url}

       unless election_record.datastreams['RECORD-XML-2'].nil? 
         election_record.datastreams['RECORD-XML-2'].delete
       end
       
       unless  election_record.datastreams['RECORD-XML'].nil?
         election_record.datastreams['RECORD-XML'].delete
       end

       election_record.save!

       election_record = TuftsVotingRecord.find(pid)

       ds = election_record.create_datastream(ActiveFedora::Datastream,'RECORD-XML', ds_opts)

       election_record.add_datastream ds

       election_record.save!

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
