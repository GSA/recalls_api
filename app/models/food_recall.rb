class FoodRecall < ActiveRecord::Base
  belongs_to :recall
  attr_accessible :description, :food_type, :summary, :url
  validates_presence_of :description, :food_type, :summary, :url
  before_save :sanitize_string_fields

  private
  def sanitize_string_fields
    self.summary = StringSanitizer.sanitize(summary)
    self.description = StringSanitizer.sanitize(description)
  end
end
