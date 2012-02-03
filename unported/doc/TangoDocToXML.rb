# Convert Tango documentation to XML
# Public domain

require 'hpricot'
require 'open-uri'

def parseLevel(source, doc)
  headers = doc/"> dl > dt"
  descs = doc/"> dl > dd"

  headers.zip(descs).each do |h, d|
    text = h.innerText.gsub(/[\r\n]/, ' ').gsub(/explorer\.outline\.addDecl\([^)]*\);/, '').gsub('"', '&quot;').squeeze(" ").strip
    type = "method"
    case text
    when /^class/  then type = "class"
    when /^struct/ then type = "struct"
    end
    if type == "method"
      puts %Q{<page title="#{text}" type="method" url="#{source}" />}
      parseLevel(source, d)
    else
      puts %Q{<page title="#{text}" type="#{type}" url="#{source}">}
      parseLevel(source, d)
      puts "</page>"
    end
  end
end

index = "http://dsource.org/projects/tango/docs/current/"
indexDoc = Hpricot(open(index))

puts "<pages>"

(indexDoc/"#searchable ul li a").each do |a|
  source = index + a.attributes["href"]
  $stderr.puts source
  # Skip: there are errors in the html of those files
  if source =~ /tango\.core\.Variant/ or source =~ /tango\.util\.Convert/
    $stderr.puts "Skipping #{source}..."
    next
  end
  begin
    fullDoc = Hpricot(open(source))
    docbody = fullDoc/"#docbody"
    puts %Q{<page title="#{(fullDoc/:head/:title).text}" type="package" url="#{source}">}
    parseLevel(source, docbody)
    puts "</page>"
  rescue OpenURI::HTTPError => e
    $stderr.puts "Error with #{source}: #{e.message}"
  end
end

puts "</pages>"
