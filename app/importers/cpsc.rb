class CPSC
  URL = 'https://www.saferproducts.gov/RestWebServices/Recall'

  def self.get_recalls(extra_params = {})
    params = { format: 'json' }.merge(extra_params)
    response = Typhoeus.get(URL, params: params)
    unless response.success?
      raise response.return_message
    end

    JSON.parse(response.body)
  end
end
