class FoodRecall < ActiveRecord::Base
  belongs_to :recall
  attr_accessible :description, :food_type, :summary, :url
  validates_presence_of :description, :food_type, :summary, :url
end
