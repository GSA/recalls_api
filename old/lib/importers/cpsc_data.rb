require 'rexml/document'

module CpscData
  extend Importer

  def self.import_from_xml_feed(url)
    begin
      REXML::Document.new(Net::HTTP.get(URI(url))).elements.each('message/results/result') do |element|
        recall_number = element.attributes['recallNo']

        Recall.transaction do
          recall = Recall.where(organization: 'CPSC', recall_number: recall_number).first_or_initialize
          recall.y2k = element.attributes['y2k']
          recall.recalled_on = Date.parse(element.attributes['recDate']) rescue nil
          recall_url = element.attributes['recallURL'].strip
          recall.url = get_cpsc_url(recall_number, URI(recall_url)) || recall_url

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
                                          detail_value: StringSanitizer.sanitize(detail_value)).first_or_create!
            end
          end
          recall.save!
        end
      end
    rescue => e
      Rails.logger.error(e.message)
    end
  end

  def self.get_cpsc_url(recall_number, recall_url)
    cpsc_url = get_url_from_redirect(URI(recall_url))
    unless cpsc_url
      legacy_url = "http://www.cpsc.gov/cpscpub/prerel/prhtml#{recall_number[0..1]}/#{recall_number}.html"
      params = {query: legacy_url, OldURL: true, autodisplay: true }
      search_url = "http://cs.cpsc.gov/ConceptDemo/SearchCPSC.aspx?#{params.to_param}"
      cpsc_url = get_url_from_redirect(URI(search_url))
    end
    cpsc_url
  end
end
