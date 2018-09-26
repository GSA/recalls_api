require 'rails_helper'
require 'vcr_helper'

RSpec.describe CPSC do
  def stub_request(response)
    Typhoeus.stub(CPSC::URL).and_return(response)
  end

  it "returns the data" do
    VCR.use_cassette('cpsc') do
      data = CPSC.get_recalls(RecallDescription: 'BlueStar')
      expect(data.size).to eq(3)
    end
  end

  it "raises an exception on a failure" do
    response = Typhoeus::Response.new(code: 500)
    stub_request(response)
    expect { CPSC.get_recalls }.to raise_error(ApiError)
  end
end
