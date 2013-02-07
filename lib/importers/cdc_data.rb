class CdcData
  def self.import_from_rss_feed(url, food_type)
    require 'rss/2.0'
    begin
      RSS::Parser.parse(Net::HTTP.get(URI(url))).items.each do |item|
        food_recall = FoodRecall.new(
            description: item.description,
            food_type: food_type,
            summary: item.title,
            url: item.link)

        next unless food_recall.valid?

        Recall.where(organization: 'CDC',
                     recall_number: Digest::MD5.hexdigest(item.link.downcase)[0, 10]).first_or_create! do |r|
          r.recalled_on = item.pubDate.to_date
          r.food_recall = food_recall
        end
      end
    rescue => e
      Rails.logger.error(e.message)
    end
  end
end