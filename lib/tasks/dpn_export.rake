require 'csv'
require 'active_fedora'
require 'fileutils'
require 'open-uri'
require 'uri'
require 'foxml_utils'


namespace :tufts_data do

  @dpn_logger = Logger.new('dpn.log')

  task :dpn_export, [:arg1, :arg2,:arg3] => :environment do |t, args|


    if args[:arg1].nil?
      puts 'YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!'
      next
    end

    if args[:arg2].nil?
      puts 'YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!'
      next
    end
    
    if args[:arg3].nil?
      puts 'YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!'
      next
    end

    capture_collections = []
    CSV.foreach(args[:arg2], encoding: 'ISO8859-1') do |row|
      pid = row[0].gsub(" ","")
      capture_collections.push(pid)
    end


    CSV.foreach(args[:arg3], encoding: 'ISO8859-1') do |row|
      pid = row[0].gsub(" ","")
      rcr = TuftsBase.find(pid)
      xml = Nokogiri::XML(rcr.datastreams['RCR-CONTENT'].content)
      xml.remove_namespaces!
      xml.xpath('//resourceRelation/objectXMLWrap/ead/archdesc/did/unitid/text()').each do |node| 
        col = node.to_s
        next unless capture_collections.include? col
        source_file = rcr.local_path_for('RCR-CONTENT')
        export_file(source_file, rcr.pid, col)
      end 
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

        if (!capture_collections.include?(collection))
          puts "#{collection} not in captured collections #{capture_collections.to_s}"
          next
        end
        next if dry_run

        case record.class.to_s
          when 'TuftsVideo'
            process_tei(record, collection)
            process_video(record, collection)
          when 'TuftsAudio'
            process_tei(record, collection)
            process_audio(record, collection)
          when 'TuftsEAD'
            process_tei(record, collection)
          when 'TuftsTEI'
            process_tei(record, collection)
          when 'TuftsRCR'
            process_rcr(record, collection)
          when 'TuftsPdf'
            process_pdf(record, collection)
          when 'TuftsImage'
            process_image(record, collection)
          when 'TuftsVotingRecord'
            process_voting_record(record, collection)
          when 'TuftsGenericObject'
            process_generic_object(record, collection)
          else
            @dpn_logger.error "#{record.class} for #{pid} unknown"
        end

        # get foxml
        # /export?context=migratej
        url = "http://repository01.lib.tufts.edu:8080/fedora/objects/PIDHERE/export?context=archive"
        url = url.gsub("PIDHERE",record.pid)
        dpn_directory = '/tdr/data05/tufts/dpn'
        base_name = 'metadata.xml'
        pid = record.pid
        pid = pid.gsub(":","_").gsub(".","_")
        dest_folder = "#{dpn_directory}/#{collection}/#{pid}"
        dest = "#{dpn_directory}/#{collection}/#{pid}/#{base_name}"
        FileUtils.mkdir_p(dest_folder) unless File.exist?(dest_folder)
        open(dest, 'wb') do |file|
          file << open(url, http_basic_authentication: [ActiveFedora.fedora_config.credentials[:user], ActiveFedora.fedora_config.credentials[:password]]).read
        end
        FoxmlUtils.clean_up(dest)
      rescue => exception
        @dpn_logger.error "ERROR There was an error collecting data for: #{pid}"
        puts exception
        puts exception.backtrace
        next
      end
    end
  end

  private

  def process_generic_object(record, collection)
    xml_doc = Nokogiri::XML(record.datastreams['GENERIC-CONTENT'].content)
    xml_doc.remove_namespaces!

    # Based on Generic Objects only having 1 file, which is true so far.
    link = xml_doc.xpath('//link')[0].text
    begin
      download = open(link)
    rescue OpenURI::HTTPError
      @dpn_logger.error "LINK : #{link}"
    end
    uri = URI.parse(link)
    dpn_directory = '/tdr/data05/tufts/dpn'
    base_name = File.basename uri.path
    pid = record.pid
    pid = pid.gsub(":","_") 
    pid_folder = pid.gsub(".","_")
    dest_folder = "#{dpn_directory}/#{collection}/#{pid_folder}"
    dest = "#{dpn_directory}/#{collection}/#{pid_folder}/#{base_name}"
    #@dpn_logger.info "LINK : #{link}"
    FileUtils.mkdir_p(dest_folder) unless File.exist?(dest_folder)

    File.open(dest, "w") do |f|
      IO.copy_stream(download, f)
    end
  end

  def process_voting_record(record, collection)
    if File.file? record.local_path_for 'RECORD-XML'
      source_file = record.local_path_for('RECORD-XML')
      export_file(source_file, record.pid, collection)
    else
      @dpn_logger.error "#{record.class} #{record.pid} missing RECORD-XML datastream file?"
    end
  end

  def process_video(record, collection)
    if File.file? record.local_path_for 'Archival.video'
      source_file = record.local_path_for('Archival.video')
      export_file(source_file, record.pid, collection)
    else
      @dpn_logger.error "#{record.class} #{record.pid} missing Archival.video  datastream file?"
      @dpn_logger.error "#{record.local_path_for('Archival.video')}  datastream file?"
    end

  end

  def process_audio(record, collection)
    if File.file? record.local_path_for('ARCHIVAL_WAV', 'wav')
      source_file = record.local_path_for('ARCHIVAL_WAV', 'wav')
      export_file(source_file, record.pid, collection)
    else
      @dpn_logger.error "#{record.class} #{record.pid} missing ARCHIVAL_WAV  datastream file?"
      @dpn_logger.error "#{record.local_path_for('ARCHIVAL_WAV')}  datastream file?"
    end

  end

  def process_tei(record, collection)
    if File.file? record.local_path_for 'Archival.xml'
      source_file = record.local_path_for('Archival.xml')
      export_file(source_file, record.pid, collection)
    else
      @dpn_logger.error "#{record.class} #{record.pid} missing Archival.xml  datastream file?"
      @dpn_logger.error "#{record.local_path_for('Archival.xml')}  datastream file?"
    end

  end

  def process_rcr(record, collection)
    if File.file? record.local_path_for 'RCR-CONTENT'
      source_file = record.local_path_for('RCR-CONTENT')
      export_file(source_file, record.pid, collection)
    else
      @dpn_logger.error "#{record.class} #{record.pid} missing RCR-CONTENT  datastream file?"
      @dpn_logger.error "#{record.local_path_for('RCR-CONTENT')}  datastream file?"
    end

  end
  def process_pdf(record, collection)
    if File.file? record.local_path_for 'Archival.pdf'
      source_file = record.local_path_for('Archival.pdf')
      export_file(source_file, record.pid, collection)
    else
      @dpn_logger.error "#{record.class} #{record.pid} missing Archival.pdf  datastream file?"
      @dpn_logger.error "#{record.local_path_for('Archival.pdf')}  datastream file?"
    end

  end

  def process_image(record, collection)
    if File.file? record.local_path_for 'Archival.tif'
      source_file = record.local_path_for('Archival.tif')
      export_file(source_file, record.pid, collection)
    else
      @dpn_logger.error "#{record.class} #{record.pid} missing Archival.tif datastream file?"
    end

  end

  def export_file(file, pid, collection)
    dpn_directory = '/tdr/data05/tufts/dpn'
    pid = pid.gsub(":","_").gsub(".","_")
    base_name = File.basename file
    base_name = base_name.gsub(":","_")
    dest = "#{dpn_directory}/#{collection}/#{pid}/#{base_name}"
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

    collection.slice!('info:fedora/') unless collection.nil?

    if collection.nil? || collection == ''
      collection = record.source
    end

   collection = collection.first if collection.kind_of?(Array)

    if collection.nil? || collection.length < 2 || collection.length > 140
      collection = 'uncollected'
    else
      # /[a-zA-Z]{2}\d+/
      puts "#{collection}"
      collection = collection.gsub("UA069","").match(/[a-zA-Z]{2}\d+/)
      #collection = collection.to_s
      puts "#{collection}"
    end
    collection = 'uncollected' if collection =~ /^[a-zA-Z]{2}/

    if collection.blank?
      collection = 'uncollected'
    end

    collection.to_s
    
  end
end
