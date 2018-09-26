require 'test_helper'

class CPSCTest < ActiveSupport::TestCase
  test "returns the data" do
    fixture = File.expand_path('../../fixtures/files/cpsc.json', __FILE__)
    data = File.read(fixture)
    response = Typhoeus::Response.new(code: 200, body: data.to_json)
    Typhoeus.stub(CPSC::URL).and_return(response)

    assert_equal data, CPSC.get_recalls
  end
end
