class RecallDetail < ActiveRecord::Base
  belongs_to :recall
  attr_accessible :detail_type, :detail_value
  validates_presence_of :detail_type, :detail_value
end
