module StringSanitizer
  def self.sanitize(str)
    CGI.unescapeHTML(Sanitize.clean(str)).squish if str
  end
end