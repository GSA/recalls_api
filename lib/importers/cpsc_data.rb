require 'rexml/document'

class CpscData
  def self.import_from_xml_feed(url)
    begin
      REXML::Document.new(Net::HTTP.get(URI(url))).elements.each('message/results/result') do |element|
        recall_number = element.attributes['recallNo']

        Recall.transaction do
          recall = Recall.where(organization: 'CPSC', recall_number: recall_number).first_or_initialize
          recall.y2k = element.attributes['y2k']
          recall.recalled_on = Date.parse(element.attributes['recDate']) rescue nil

          attributes = {
              manufacturer: element.attributes['manufacturer'],
              product_type: element.attributes['type'],
              description: element.attributes['prname'],
              upc: element.attributes['UPC'],
              hazard: element.attributes['hazard'],
              country: element.attributes['country_mfg']
          }

          Recall::CPSC_DETAIL_TYPES.each do |detail_type|
            detail_value = attributes[detail_type.underscore.to_sym]
            next if detail_value.blank?

            if recall.new_record?
              recall.recall_details << RecallDetail.new(detail_type: detail_type,
                                                        detail_value: detail_value)
            else
              recall.recall_details.where(detail_type: detail_type,
                                          detail_value: detail_value).first_or_create!
            end
          end
          recall.save!
        end
      end
    rescue => e
      Rails.logger.error(e.message)
    end
  end
end