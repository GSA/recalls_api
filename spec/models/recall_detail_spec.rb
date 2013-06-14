require 'spec_helper'

describe RecallDetail do
  disconnect_sunspot
  it { should validate_presence_of :detail_type }
  it { should validate_presence_of :detail_value }
  it { should validate_uniqueness_of(:detail_value).scoped_to(:recall_id, :detail_type).case_insensitive }
  it { should belong_to :recall }
end
