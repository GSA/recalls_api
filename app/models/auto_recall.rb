class AutoRecall < ActiveRecord::Base
  belongs_to :recall
  attr_accessible :component_description, :make, :manufacturer, :manufacturing_begin_date, :manufacturing_end_date, :model, :recalled_component_id, :year

  def as_json(options = {})
    hash = super(options)
    hash['manufacturing_begin_date'] = manufacturing_begin_date.strftime('%Y-%m-%d') if manufacturing_begin_date and hash.include?('manufacturing_begin_date')
    hash['manufacturing_end_date'] = manufacturing_end_date.strftime('%Y-%m-%d') if manufacturing_end_date and hash.include?('manufacturing_end_date')
    hash
  end
end
