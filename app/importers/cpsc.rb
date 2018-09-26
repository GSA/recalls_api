class CPSC
  URL = 'https://www.saferproducts.gov/RestWebServices/Recall?format=json'

  def self.get_recalls
    response = Typhoeus.get(URL)
    unless response.success?
      raise response.return_message
    end

    JSON.parse(response.body)
  end
end
