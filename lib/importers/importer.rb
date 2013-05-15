module Importer
  def get_url_from_redirect(uri)
    res = Net::HTTP.get_response(uri)
    location = %w(301 302).include?(res.code) ? (res.get_fields('Location') || []) : []
    location.first
  end
end