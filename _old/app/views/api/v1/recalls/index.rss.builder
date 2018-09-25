xml.instruct! :xml, :version => "1.0"
xml.rss(:version => "2.0", "xmlns:atom" => "http://www.w3.org/2005/Atom") do
  xml.channel do
    xml.title "USA.gov Recalls Feed"
    xml.description "Recent recalls from around the US Government"
    xml.link "http://#{RECALLS_API_HOST}/api/recalls.rss"
    xml.atom(:link, "href" => "http://#{RECALLS_API_HOST}/api/recalls.rss", "rel" => "self", "type" => "application/rss+xml")

    @recalls.results.each do |recall|
      xml.item do
        xml.title recall.summary
        xml.description recall.description
        xml.link recall.recall_url
        xml.pubDate recall.recalled_on.strftime('%a, %d %b %Y 00:00:00 +0000')
        xml.guid recall.recall_url
      end
    end
  end
end