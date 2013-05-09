class CdcData
  def self.import_from_rss_feed(url, food_type, authoritative_source = false)
    require 'rss/2.0'
    begin
      RSS::Parser.parse(Net::HTTP.get(URI(url))).items.each do |item|
        next if item.link.blank? or item.title.blank? or item.description.blank?

        recall_url = fetch_source_url(item.link.strip)
        food_recall = FoodRecall.where(url: recall_url).first_or_initialize
        food_recall.description = item.description
        food_recall.food_type = food_type
        food_recall.summary = item.title
        next unless food_recall.valid?

        recall = Recall.where(organization: extract_organization(recall_url),
                              recall_number: Digest::MD5.hexdigest(recall_url.downcase)[0, 10]).first_or_initialize
        next unless recall.new_record? || authoritative_source
        recall.recalled_on = item.pubDate.to_date
        recall.food_recall = food_recall
        food_recall.save if recall.save
      end
    rescue => e
      Rails.logger.error(e.message)
    end
  end

  def self.fetch_source_url(url)
    uri = URI(url)
    source_url = get_url_from_redirect(uri) if uri.host =~ /\.cdc\.gov$/i
    source_url ||= url
    source_url
  end

  def self.get_url_from_redirect(uri)
    res = Net::HTTP.get_response(uri)
    if res.code == '302'
      doc = Nokogiri::HTML(res.body)
      doc.css('a').first.attr(:href) if doc.css('a').present?
    end
  end

  def self.extract_organization(url)
    URI(url).host.upcase.scan(/([[:alnum:]]+)\.gov$/i).flatten.first
  end
end