class FoodRecall < ActiveRecord::Base
  belongs_to :recall
  attr_accessible :description, :food_type, :summary, :url
  validates_presence_of :description, :food_type, :summary, :url
  before_save :squish_string_fields

  private
  def squish_string_fields
    self.summary = summary.squish if summary.present?
    self.description = description.squish if description.present?
  end
end
