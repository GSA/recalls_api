require 'spec_helper'

describe RecallDetail do
  disconnect_sunspot
  it { should validate_presence_of :detail_type }
  it { should validate_presence_of :detail_value }
  it { should belong_to :recall }
end