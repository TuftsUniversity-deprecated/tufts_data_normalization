require 'active_fedora'
require 'yaml'

namespace :tufts_data do
  @solr = ""

  desc 'List all fields, and their usage stats'
  task :audit_fields => :environment do |t|

    unmappedSolrFields = []

    getAllFields.sort.each do |field|

      if( !getMapped.has_key?(field) )
        unmappedSolrFields.push(field)
        next
      end

      results = getCounts(field)
      displayCounts(field, results)

    end #End fields.each

    puts "\n\n"
    puts "------ Unused Metadata Fields? (No Apparent Matching Solr Field) ------"
    getUndefined.sort.each do |udef|
      puts udef
    end

    puts "\n\n"
    puts "------ Unmapped Solr Fields ------"
    unmappedSolrFields.each do |field|
      results = getCounts(field)
      if(results['response']['numFound'] > 0)
        displayCounts(field, results)
      end
    end

  end #End task audit_fields

  def getSolr
    if(String === @solr)
      creds = YAML.load_file("config/solr.yml")
      @solr = RSolr.connect(:url => creds[Rails.env]['url'])
    else
      @solr
    end
  end

  def getAllFields
    getSolr.get(
      'select',
      :params => {
        :q => '*:*',
        :rows => 0,
        :wt => 'csv'
      }
    ).split(",")
  end

  def getCounts(field)
    getSolr.select(
      :params => {
        :q => "#{field}:[* TO *] id:tufts*",
        :rows => 0,
        :facet => "true",
        "facet.field" => "steward_tesim"
      },
      :method => :get
    )
  end

  def displayCounts(field, results)
    display = getMapped.has_key?(field) ? "#{getMapped[field]} " : ""

    puts
    puts "--- #{display}(#{field}) ---".gsub(/\r?\n?/, "")
    puts "total: #{results['response']['numFound']}"

    #Facets come back as an array instead of a hash for some awful reason.
    name = false
    results["facet_counts"]["facet_fields"]["steward_tesim"].each do |nameOrNum|
      if(name == false)
        name = nameOrNum
      else
        puts "#{name}: #{nameOrNum}"
        name = false
      end
    end

  end # End displayCounts

  def getMapped
    {
      "id" => "Pid",

      "title_tesim"       => "Title",
      "alternative_tesim" => "Alternative Title",
      "creator_tesim"     => "Creator",
      "contributor_tesim" => "Contributor",
      "description_tesim"  => "Description",

      "abstract_tesim"   => "Abstract",
      "publisher_tesim"  => "Publisher",
      "source_tesim"     => "Source",
      "date_tesim"      => "Date",

      "date_created_tesim"          => "Date Created",
      "date_created_formatted_tesim" => "Date Created (formatted)",
      "date_submitted_tesim"        => "Date Submitted",
      "date_issued_tesim"           => "Date Issued",
      "date_available_tesim"        => "Date Available",
      "date_modified_tesim"         => "Date Modified",

      "language_tesim" => "Language",
      "type_tesim"     => "Type",
      "format_tesim"   => "Format",
      "extent_tesim"   => "Extent",

      "persname_tesim" => "Personal Name",
      "corpname_tesim" => "Corporate Name",
      "geogname_tesim" => "Geographic Name",

      "subject_tesim"    => "Subject",
      "genre_tesim"      => "Genre",
      "provenance_tesim" => "Provenance",
      "rights_tesim"     => "Rights",

      "access_rights_tesim" => "Access Rights",
      "rights_holder_tesim" => "Rights Holder",
      "license_tesim"       => "License",

      "isFormatOf_tesim" => "is Format of",
      "isPartOf_tesim"   => "is Part of (1)",
      "is_part_of_ssim"  => "is Part of (2)",

      "accrualPolicy_tesim" => "Accrual Policy",
      "spatial_tesim"       => "Spatial",
      "temporal_tesim"      => "Temporal",
      "funder_tesim"        => "Funder",

      "bibliographic_citation_tesim" => "Bibliographic Citation",

      "resolution_tesim" => "Resolution",
      "steward_tesim"    => "Steward",

      "note_tesim"      => "Internal Note",
      "displays_ssim"   => "Displays in Portal",
      "embargo_dtsim"   => "Embargo",
      "status_tesim"    => "Status",
      "visibility_ssim" => "Visibility",
      "batch_id_ssim"   => "Batch ID"
    }
  end

  def getUndefined
    [
      "Table of Contents",
      "Date Copyrighted",
      "Date Accepted",
      "Medium",
      "Replaces",
      "is Replaced by",
      "Has Part",
      "Audience",
      "References",
      "Bit Depth",
      "Color Space",
      "File Size",
      "Permanent URL",
      "Record Created by",
      "Createdby",
      "Retention Period",
      "Start Date",
      "Expiration Date",
      "Quality Review Status",
      "Rejection Reason",
      "QR Note",
      "Creatordept",
      "Depositor"
    ]
  end

end

