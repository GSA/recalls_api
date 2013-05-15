require 'spec_helper'

describe CpscData do
  disconnect_sunspot

  describe '.import_from_xml_feed' do
    let(:url) { 'http://www.cpsc.gov/cgibin/CPSCUpcWS/CPSCUpcSvc.asmx/getRecallByDate?endDate=2012-04-01&password=&startDate=2010-04-01&userId='.freeze }

    before { Recall.destroy_all }

    context 'when the url returns a valid response' do
      let(:content) { File.read("#{Rails.root}/spec/fixtures/xml/cpsc.xml").freeze }
      before do
        Net::HTTP.should_receive(:get).
            at_least(:once).
            with(URI(url)).
            and_return(content)
        CpscData.should_receive(:get_cpsc_url).
            at_least(:once).
          with('10187', URI('http://cs.cpsc.gov/ConceptDemo/SearchCPSC.aspx?SearchCategory=Recalls%20News%20Releases&category=995,1098,990,991,992,993,994,1031&autodisplay=true&query=10187')).
          and_return('http://www.cpsc.gov/en/Recalls/2010/Crate-and-Barrel-Recalls-Glass-Water-Bottles-Due-to-Laceration-Hazard/')
        CpscData.should_receive(:get_cpsc_url).
            with('10727', URI('http://cs.cpsc.gov/ConceptDemo/SearchCPSC.aspx?SearchCategory=Recalls%20News%20Releases&category=995,1098,990,991,992,993,994,1031&autodisplay=true&query=10727')).
            and_return(nil)
      end

      it 'should persist CPSC data' do
        CpscData.import_from_xml_feed(url)
        Recall.count.should == 2

        first_recall = Recall.find_by_recall_number('10187')
        first_recall.y2k.should == 110187
        first_recall.recalled_on.to_s(:db).should == '2010-04-01'
        first_recall.url.should == 'http://www.cpsc.gov/en/Recalls/2010/Crate-and-Barrel-Recalls-Glass-Water-Bottles-Due-to-Laceration-Hazard/'

        first_recall.recall_details.count.should == 7
        recall_details = {}
        first_recall.recall_details.each do |rd|
          if recall_details[rd.detail_type].nil?
            recall_details[rd.detail_type] = [rd.detail_value]
          else
            recall_details[rd.detail_type] << rd.detail_value
          end
        end

        recall_details['Manufacturer'].should == ['Crate & Barrel']
        recall_details['ProductType'].should == ['Bottles (Sports/Water/Thermos)']
        recall_details['Description'].should == ['Glass Water Bottles']
        recall_details['UPC'].should == %w(987654321 876543219)
        recall_details['Hazard'].should == %w(Laceration)
        recall_details['Country'].should == %w(China)

        recall = Recall.find_by_recall_number('10727')
        recall.y2k.should == 110187
        recall.recalled_on.to_s(:db).should == '2010-04-01'
        recall.url.should == 'http://cs.cpsc.gov/ConceptDemo/SearchCPSC.aspx?SearchCategory=Recalls%20News%20Releases&category=995,1098,990,991,992,993,994,1031&autodisplay=true&query=10727'

        recall_details = {}
        recall.recall_details.each do |rd|
          if recall_details[rd.detail_type].nil?
            recall_details[rd.detail_type] = [rd.detail_value]
          else
            recall_details[rd.detail_type] << rd.detail_value
          end
        end
        recall_details['UPC'].should be_nil
      end
    end

    context 'when the url returns an invalid response' do
      before do
        Net::HTTP.should_receive(:get).
            with(URI(url)).
            and_raise(SocketError, 'getaddrinfo: nodename nor servname provided, or not known')
      end

      it 'should log the error' do
        Rails.logger.should_receive(:error).with('getaddrinfo: nodename nor servname provided, or not known')
        CpscData.import_from_xml_feed(url)
      end
    end
  end

  describe '.get_cpsc_url' do
    context 'when recall_url does not redirect' do
      it 'should try get_url_from_redirect using the old URL format' do
        CpscData.should_receive(:get_url_from_redirect).
            with(URI('http://cs.cpsc.gov/ConceptDemo/SearchCPSC.aspx?SearchCategory=Recalls%20News%20Releases&category=995,1098,990,991,992,993,994,1031&autodisplay=true&query=10187')).
            and_return(nil)
        CpscData.should_receive(:get_url_from_redirect).
            with(URI('http://cs.cpsc.gov/ConceptDemo/SearchCPSC.aspx?OldURL=true&autodisplay=true&query=http%3A%2F%2Fwww.cpsc.gov%2Fcpscpub%2Fprerel%2Fprhtml10%2F10187.html')).
            and_return('http://www.cpsc.gov/en/Recalls/2010/Crate-and-Barrel-Recalls-Glass-Water-Bottles-Due-to-Laceration-Hazard/')

        CpscData.get_cpsc_url('10187', 'http://cs.cpsc.gov/ConceptDemo/SearchCPSC.aspx?SearchCategory=Recalls%20News%20Releases&category=995,1098,990,991,992,993,994,1031&autodisplay=true&query=10187').
            should == 'http://www.cpsc.gov/en/Recalls/2010/Crate-and-Barrel-Recalls-Glass-Water-Bottles-Due-to-Laceration-Hazard/'
      end
    end
  end
end