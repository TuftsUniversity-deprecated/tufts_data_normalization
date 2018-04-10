require 'nokogiri'
require 'open-uri'
require 'base64'

# modified from : http://codegists.com/snippet/ruby/cleanupexportedavalonobjectrb_cjcolvar_ruby
module FoxmlUtils 

def self.clean_up(filename)
  f = File.new filename
  doc = Nokogiri::XML::Document.parse f
  f.close

  puts "PID : #{filename}"

  #Get rid of Audit trail
  begin
    doc.xpath("//foxml:datastream[@ID='AUDIT']").each {|n| n.remove()}
  rescue Nokogiri::XML::XPath::SyntaxError
    puts "Audit Error"
  end
  #Keep only the last version of a datastream
  begin
    doc.xpath("//foxml:datastreamVersion[position() < last()]").each {|n| n.remove()}
    doc.xpath("//foxml:datastreamVersion").each do |n|
      n.remove_attribute("CREATED")
      n.remove_attribute("SIZE")
      n["ID"] = n["ID"].gsub(/\.[1-9]+/,".0")
    end
  rescue Nokogiri::XML::XPath::SyntaxError
    puts "DatastreamVersion Error"
  end

  #set all datastreams versionable false
  begin
    doc.xpath("//foxml:datastream").each {|n| n["VERSIONABLE"] = "false"}
  rescue Nokogiri::XML::XPath::SyntaxError
    puts "Versionable Error"
  end

  #change M datastreams to X for type xml
  begin
    doc.xpath("//foxml:datastreamVersion[@MIMETYPE='text/xml']/..").each {|ds| ds["CONTROL_GROUP"] = "X"}
  rescue Nokogiri::XML::XPath::SyntaxError
    puts "MimeType Error"
  end

  #Decode binaryContent
  nodeset = doc.xpath("//foxml:datastreamVersion[@MIMETYPE='text/xml']/foxml:binaryContent/..")
  nodeset.each do |node|
    childdoc = Nokogiri::XML::DocumentFragment.parse Base64.decode64(node.content.gsub(/\s+/,''))
    node.children = '<xmlContent>' #This is getting transformed to xmlcontent and fedora is complaining!!!
    node.child.children = childdoc
    node.child.child.traverse {|n| n.namespace = nil}
  end

  # remve payload streams
  doc.xpath("//foxml:datastream[@ID='ARCHIVAL_WAV']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='ARCHIVAL_XML']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='ACCESS_MP3']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='Archival.xml']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='Thumbnail.png']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='Archival.tif']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='Advanced.jpg']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='Basic.jpg']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='Transfer.binary']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='Archival.pdf']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='RCR-CONTENT']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='GENERIC-CONTENT*']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='Archival.video']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='ARCHIVAL_XML']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='Access.webm']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='Access.mp4']").each {|n| n.remove()}
  doc.xpath("//foxml:datastream[@ID='RECORD-XML']").each {|n| n.remove()}

  # write out new file
  f2 = File.new filename, 'w+'
  f2.write doc.to_s.gsub('xmlcontent','xmlContent').gsub(/^\s*$\n/, '') #HACK fix for xmlContent and cleanup nokogiri's blank lines
  f2.close
end
end
