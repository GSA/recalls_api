# coding: utf-8
require 'spec_helper'

describe CdcData do
  disconnect_sunspot
  describe '.import_from_rss_feed' do

    before { Recall.destroy_all }

    context 'when the url returns a valid response' do
      let(:feed_content) { File.read("#{Rails.root}/spec/fixtures/rss/food_recalls.rss").freeze }
      let(:redirect_content) { File.read("#{Rails.root}/spec/fixtures/html/redirect_content.html").freeze }

      before do
        Net::HTTP.should_receive(:get).
            at_least(:once).
            with(URI('http://www2c.cdc.gov/podcasts/createrss.asp?c=146')).
            and_return(feed_content)

        response = mock(Net::HTTPFound, code: '302', body: redirect_content)
        Net::HTTP.should_receive(:get_response).
            at_least(:once).
            with(URI('http://www2c.cdc.gov/podcasts/download.asp?af=h&f=8625997')).
            and_return(response)
      end

      it 'should persist food recalls' do
        CdcData.import_from_rss_feed('http://www2c.cdc.gov/podcasts/createrss.asp?c=146', 'food')

        recalls = FoodRecall.all
        recalls.count.should == 4

        recall = recalls.first
        recall.url.should == 'http://www.fsis.usda.gov/News_&_Events/Recall_028_2013_Expanded/index.asp'
        recall.summary.should == 'Louisiana Firm Recalls Cooked Meat, Poultry, and Deli Products Due To Possible Listeria Monocytogenes Contamination'
        recall.description.should == 'Manda Packing Company, a Baker, La., establishment, is expanding its recall to include approximately 468,000 pounds of roast beef, ham, turkey breast, tasso pork, ham shanks, hog head cheese, corned beef, and pastrami due to possible contamination with Listeria monocytogenes.'
        recall.food_type.should == 'food'
        recall.recall.recalled_on.should == Date.parse('Fri, 12 Apr 2013')
        recall.recall.organization.should == 'USDA'
        recall.recall.recall_number.should_not be_blank

        recall = recalls[1]
        recall.url.should == 'http://www.fsis.usda.gov/fsis_recalls/RNR_067_2012/index.asp'
        recall.summary.should == 'Recall Notification Report 067-2012 (Maple Links and Maple Patties)'
        recall.description.should == 'BEF Foods Inc., a Columbus, Ohio, corporation, is recalling approximately 1,768,600 pounds of Bob Evans® Maple Links and Maple Patties because they are misbranded in that they contain monosodium glutamate (MSG), which is not declared on the label.'
        recall.food_type.should == 'food'
        recall.recall.recalled_on.should == Date.parse('Mon, 22 Oct 2012')
        recall.recall.organization.should == 'USDA'
        recall.recall.recall_number.should_not be_blank


        recall = recalls[2]
        recall.url.should == 'http://www.fda.gov/Safety/Recalls/ucm207477.htm'
        recall.summary.should == 'Whole Foods Market Voluntarily Recalls Frozen Whole Catch Yellow Fin Tuna Steaks Due to Possible Health Risks'
        recall.description.should == 'Whole Foods Market announced the recall of its Whole Catch Yellow fin Tuna Steaks (frozen) with a best by date of Dec 5th, 2010 because of possible elevated levels of histamine that may result in symptoms that generally appear within minutes to an hour after eating the affected fish. No other Whole Foods Market, Whole Catch, 365 or 365 Organic products are affected.'
        recall.food_type.should == 'food'
        recall.recall.recalled_on.should == Date.parse('Mon, 05 Apr 2010')
        recall.recall.organization.should == 'FDA'
        recall.recall.recall_number.should_not be_blank

        recall = recalls[3]
        recall.url.should == 'http://www.fda.gov/Safety/Recalls/ucm207345.htm'
        recall.summary.should == 'Golden Pacific Foods, Inc. Issues Allergy Alert for Undeclared Milk and Soy in Marco Polo Brand Shrimp Snacks'
        recall.description.should == 'Chino, California (April 2, 2010) -- Golden Pacific Foods, Inc. is recalling Marco Polo Brand Shrimp Snacks sold as Original, Onion & Garlic Flavored and Bar-B-Que Flavored, because they may contain undeclared milk and soy. People who have allergies to milk and soy run the risk of serious or life-threatening reaction if they consume these products.'
        recall.food_type.should == 'food'
        recall.recall.recalled_on.should == Date.parse('Sun, 04 Apr 2010')
        recall.recall.organization.should=='FDA'
        recall.recall.recall_number.should_not be_blank
      end

      it 'should not recreate recalls that have already been loaded' do
        CdcData.import_from_rss_feed('http://www2c.cdc.gov/podcasts/createrss.asp?c=146', 'food', true)
        Recall.all.size.should == 4
        FoodRecall.all.size.should == 4

        CdcData.import_from_rss_feed('http://www2c.cdc.gov/podcasts/createrss.asp?c=146', 'food', true)
        Recall.all.size.should == 4
        FoodRecall.all.size.should == 4
      end
    end

    context 'when the url returns an invalid response' do
      before do
        Net::HTTP.should_receive(:get).
            with(URI('http://www2c.cdc.gov/podcasts/createrss.asp?c=146')).
            and_raise(SocketError, 'getaddrinfo: nodename nor servname provided, or not known')
      end

      it 'should log the error' do
        Rails.logger.should_receive(:error).with('getaddrinfo: nodename nor servname provided, or not known')
        CdcData.import_from_rss_feed('http://www2c.cdc.gov/podcasts/createrss.asp?c=146', 'food')
      end
    end

    context 'when data is from authoritative source' do
      before do
        Net::HTTP.should_receive(:get).
            with(URI('http://www.fsis.usda.gov/RSS/usdarss.xml')).
            and_return(File.read("#{Rails.root}/spec/fixtures/rss/usda.rss"))
        Net::HTTP.should_receive(:get).
            with(URI('http://www2c.cdc.gov/podcasts/createrss.asp?c=146')).
            and_return(File.read("#{Rails.root}/spec/fixtures/rss/food_recalls.rss"))
      end

      it 'should not be overridden by non authoritative source' do
        CdcData.import_from_rss_feed('http://www.fsis.usda.gov/RSS/usdarss.xml', 'food', true)
        CdcData.import_from_rss_feed('http://www2c.cdc.gov/podcasts/createrss.asp?c=146', 'food')
        recall = Recall.find_by_recall_number('523077f478')
        recall.summary.should == 'original Louisiana Firm Recalls Cooked Meat, Poultry, and Deli Products Due To Possible Listeria Monocytogenes Contamination'
      end
    end
  end

  describe '.get_url_from_redirect' do
    context 'when the response body is blank' do
      it 'should return nil' do
        uri = URI('http://www2c.cdc.gov/podcasts/download.asp?af=h&f=8625997')
        response = mock(Net::HTTPFound, code: '302', body: '')
        Net::HTTP.should_receive(:get_response).with(uri).and_return(response)
        CdcData.get_url_from_redirect(uri).should be_nil
      end
    end
  end
end