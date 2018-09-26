require 'test_helper'

class CPSCTest < ActiveSupport::TestCase
  def stub_request(response)
    Typhoeus.stub(CPSC::URL).and_return(response)
  end

  test "returns the data" do
    VCR.use_cassette('cpsc') do
      data = CPSC.get_recalls(RecallDescription: 'BlueStar')
      assert_equal 3, data.size
    end
  end

  test "raises an exception on a failure" do
    response = Typhoeus::Response.new(code: 500)
    stub_request(response)

    assert_raises do
      CPSC.get_recalls
    end
  end
end
