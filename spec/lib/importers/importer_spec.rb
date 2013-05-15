require 'spec_helper'

describe Importer do
  class DummyImporter
    extend Importer
  end

  describe '.get_url_from_redirect' do
    context 'when the response Location header field is present' do
      it 'should return the Location header field value' do
        uri = URI('http://www2c.cdc.gov/podcasts/download.asp?af=h&f=8625997')
        response = mock(Net::HTTPFound, code: '302')
        Net::HTTP.should_receive(:get_response).with(uri).and_return(response)
        response.should_receive(:get_fields).with('Location').and_return(%w(http://www.fsis.usda.gov/fsis_recalls/RNR_067_2012/index.asp))
        DummyImporter.get_url_from_redirect(uri).should == 'http://www.fsis.usda.gov/fsis_recalls/RNR_067_2012/index.asp'
      end
    end

    context 'when the response Location header field is not present' do
      it 'should return nil' do
        uri = URI('http://www2c.cdc.gov/podcasts/download.asp?af=h&f=8625997')
        response = mock(Net::HTTPFound, code: '302')
        Net::HTTP.should_receive(:get_response).with(uri).and_return(response)
        response.should_receive(:get_fields).with('Location').and_return(nil)
        DummyImporter.get_url_from_redirect(uri).should be_nil
      end
    end
  end
end