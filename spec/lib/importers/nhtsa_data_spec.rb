require 'spec_helper'

describe NhtsaData do
  disconnect_sunspot
  describe '.import_from_tab_delimited_feed' do
    let(:url) { 'http://www-odi.nhtsa.dot.gov/downloads/folders/recalls/mIBT4jvpyrRM6YJ3QIyC/flat_recalls_new.txt'.freeze }

    before { Recall.destroy_all }

    context 'when the url returns a valid response' do
      let(:content) { File.read("#{Rails.root}/spec/fixtures/txt/nhtsa_recalls.txt").freeze }
      before do
        Net::HTTP.should_receive(:get).
            at_least(:once).
            with(URI(url)).
            and_return(content)
      end

      it 'should persist NHTSA data' do
        NhtsaData.import_from_tab_delimited_feed(url)
        Recall.count.should == 3
        recall = Recall.find_by_recall_number('02E030000')
        recall.recalled_on.to_s(:db).should == '2002-04-26'

        recall_details = Hash[recall.recall_details.collect { |rd| [rd.detail_type, rd.detail_value] }]
        recall_details['ManufacturerCampaignNumber'].should be_nil
        recall_details['Code'].should == 'E'
        recall_details['PotentialUnitsAffected'].should == '15000'
        recall_details['NotificationDate'].should == '20020426'
        recall_details['Initiator'].should == 'MFR'
        recall_details['ReportDate'].should == '20020426'
        recall_details['DefectSummary'].should =~ /^GLOVE COMPARTMENT ORGANIZER SENT AS A FREE GIFT FOR A NEW CONSUMER REPORTS SUBSCRIPTION/
        recall_details['ConsequenceSummary'].should == 'IMPROPER INFLATION OF TIRES CAN POSE A SAFETY HAZARD. AN OVERHEATED FLASHLIGHT COULD RESULT IN BURNS.'
        recall_details['CorrectiveSummary'].should =~ /^CUSTOMERS SHOULD REMOVE THE BATTERIES FROM THE FLASHLIGH IMMEDIATELY/
        recall_details['Notes'].should =~ /^ALSO, CUSTOMERS CAN CONTACT THE NATIONAL HIGHWAY TRAFFIC SAFETY ADMINISTRATION\'S/
        recall_details['RecallSubject'].should == 'CONSUMER UNION/GLOVE COMPARTMENT KIT'

        auto_recall = recall.auto_recalls.first
        auto_recall.make.should == 'CONSUMERS UNION'
        auto_recall.model.should == 'GLOVE COMPARTMENT KIT'
        auto_recall.year.should be_nil
        auto_recall.component_description.should == 'UNKNOWN OR OTHER'
        auto_recall.manufacturer.should == 'CONSUMERS UNION'
        auto_recall.manufacturing_begin_date.should be_nil
        auto_recall.manufacturing_end_date.should be_nil

        recall = Recall.find_by_recall_number('02V269000')
        recall.recalled_on.to_s(:db).should == '2002-10-03'

        recall_details = Hash[recall.recall_details.collect { |rd| [rd.detail_type, rd.detail_value] }]
        recall_details['ManufacturerCampaignNumber'].should == 'SCO277'
        recall_details['Code'].should == 'V'
        recall_details['FederalMotorVehicleSafetyNumber'].should == '121'

        auto_recall = recall.auto_recalls.first
        auto_recall.year.should == 2002

        recall = Recall.find_by_recall_number('06V052000')
        recall.recalled_on.to_s(:db).should == '2006-02-16'
        recall.recall_details.where(detail_type: 'ManufacturerCampaignNumber').count.should == 1
        recall.auto_recalls.count.should == 2

        auto_recall = recall.auto_recalls.find_by_recalled_component_id('000022577000211858000000152')
        auto_recall.make.should == 'HOLIDAY RAMBLER'
        auto_recall.model.should == 'NEXT LEVEL'
        auto_recall.manufacturing_begin_date.to_s(:db).should == '2005-11-28'
        auto_recall.manufacturing_end_date.to_s(:db).should == '2006-01-20'

        auto_recall = recall.auto_recalls.find_by_recalled_component_id('000022577000211862000000152')
        auto_recall.make.should == 'MCKENZIE'
        auto_recall.model.should == 'DUNE CHASER'
        auto_recall.manufacturing_begin_date.to_s(:db).should == '2005-11-28'
        auto_recall.manufacturing_end_date.to_s(:db).should == '2006-01-20'
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
        NhtsaData.import_from_tab_delimited_feed(url)
      end
    end
  end
end