require 'csv'
require 'active_fedora'

namespace :tufts_data do
  desc 'who is using rels-ext'
  task :rels_ext_report, [:arg1] => :environment do |t, args|
    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      puts "Usage: rake tufts_data:fix_election_records['/home/hydradm/path_to/list_of_pids.txt']"
      next
    end
    output =  CSV.open("relsext.csv", "wb") 

    #gather available predicates
    predicates = []
    ActiveFedora::Predicates.predicate_config[:predicate_mapping].values.each do |x|
      predicates += x.keys.to_a
    end
    predicates = predicates - [:has_description,:is_member_of_collection,:is_member_of,:has_model, :oai_item_id]
    predicates = predicates.uniq

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
        rels = []
        predicates.each do |predicate|
          rel =  record.object_relations[predicate]
          rels << rel if rel != []
        end
        output << [pid,rels.join(',')]
      rescue ActiveFedora::ObjectNotFoundError, IO::EAGAINWaitReadable
        puts "ERROR Processing #{pid}"
      end
    end
    output.close
  end

  desc 'who is using what'
  task :fedora_4_collections, [:arg1] => :environment do |t, args|

    if args[:arg1].nil?
      puts "YOU MUST SPECIFY FULL PATH TO FILE, ABORTING!"
      puts "Usage: rake tufts_data:fix_election_records['/home/hydradm/path_to/list_of_pids.txt']"
      next
    end
    output =  CSV.open("file.csv", "wb") 
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
       object_relations = record.object_relations
       has_description_pids = [] #puts "#{pid} has description #{x}"
       has_description_exists = []
       has_description_titles = []
       unless object_relations[:has_description].empty? 
         object_relations[:has_description].each {|x| 
           has_description_pids << x  #puts "#{pid} has description #{x}"
           begin
             raise ActiveFedora::ObjectNotFoundError if x.index(',') != nil || x.index('(') != nil || x.index(')') != nil || x.index('&') != nil || x.index(';') || x.index('_') || x.index('-') || x.index('?')
puts "#{x}"
             desc = TuftsBase.find(x)
             has_description_exists << "true"
             has_description_titles << desc.title.strip
           rescue ActiveFedora::ObjectNotFoundError, IO::EAGAINWaitReadable
             has_description_exists << "false"
             has_description_titles << ""
           end

         }
       end

       collection_pids = [] #puts "#{pid} has description #{x}"
       collection_exists = []
       collection_titles = []
       unless object_relations[:is_member_of_collection].empty? 
         object_relations[:is_member_of_collection].each {|x| 
           collection_pids << x  #puts "#{pid} has description #{x}"
           begin
             raise ActiveFedora::ObjectNotFoundError if x.index(',') != nil || x.index('(') != nil || x.index(')') != nil || x.index('&') != nil || x.index(';') || x.index('_') || x.index('-') || x.index('?')
puts "#{x}"
             desc = TuftsBase.find(x)
             collection_exists << "true"
             collection_titles << desc.title.strip
           rescue ActiveFedora::ObjectNotFoundError, IO::EAGAINWaitReadable
             collection_exists << "false"
             collection_titles << ""
           end

         }
       end
       
       member_pids = [] #puts "#{pid} has description #{x}"
       member_exists = []
       member_titles = []
       unless object_relations[:is_member_of].empty? 
         object_relations[:is_member_of].each {|x| 
           member_pids << x  #puts "#{pid} has description #{x}"
           begin
             raise ActiveFedora::ObjectNotFoundError if x.index(',') != nil || x.index('(') != nil || x.index(')') != nil || x.index('&') != nil || x.index(';') || x.index('_') || x.index('-') || x.index('?')
puts "#{x}"
             desc = TuftsBase.find(x)
             member_exists << "true"
             member_titles << desc.title.strip
           rescue ActiveFedora::ObjectNotFoundError, IO::EAGAINWaitReadable
             member_exists << "false"
             member_titles << ""
           end

         }
       end
       
       part_pids = [] #puts "#{pid} has description #{x}"
       part_exists = []
       part_titles = []
       unless object_relations[:is_part_of].empty? 
         object_relations[:is_part_of].each {|x| 
           member_pids << x  #puts "#{pid} has description #{x}"
           begin
             raise ActiveFedora::ObjectNotFoundError if x.index(',') != nil || x.index('(') != nil || x.index(')') != nil || x.index('&') != nil || x.index(';') || x.index('_') || x.index('-') || x.index('?')
puts "#{x}"
             desc = TuftsBase.find(x)
             part_exists << "true"
             part_titles << desc.title.strip
           rescue ActiveFedora::ObjectNotFoundError, IO::EAGAINWaitReadable
             part_exists << "false"
             part_titles << ""
           end

         }
       end

       source = record.source | []
       steward = []
       begin  
         steward = record.steward
       rescue
         puts "no steward"
       end

      rescue => exception
        puts "ERROR There was an error doing the conversion for: #{pid}"
        puts exception.message
        puts exception.backtrace
        next
      end
      output << [pid, has_description_pids.join(','), has_description_exists.join(','), has_description_titles.join(','),collection_pids.join(','), collection_exists.join(','), collection_titles.join(','), member_pids.join(','), member_exists.join(','), member_titles.join(','), part_pids.join(','), part_exists.join(','), part_titles.join(','), source.join(','), steward.join(',')]
    end 
    output.close
  end

  def collection_code(pid)
    pid.sub(/.+:([^.]+).*/, '\1')
  end

  def pid_without_namespace(pid)
    pid.sub(/.+:(.+)$/, '\1')
  end

end
