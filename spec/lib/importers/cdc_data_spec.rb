require 'spec_helper'

describe CdcData do
  disconnect_sunspot
  describe '.import_from_rss_feed' do

    before { Recall.destroy_all }

    context 'when the url returns a valid response' do
      let(:content) { File.read("#{Rails.root}/spec/fixtures/rss/food_recalls.rss").freeze }

      before do
        Net::HTTP.should_receive(:get).
            at_least(:once).
            with(URI('http://www2c.cdc.gov/podcasts/createrss.asp?c=146')).
            and_return(content)
      end

      it 'should persist food recalls' do
        CdcData.import_from_rss_feed('http://www2c.cdc.gov/podcasts/createrss.asp?c=146', 'food')

        first = FoodRecall.first
        first.url.should == 'http://www.fda.gov/Safety/Recalls/ucm207477.htm'
        first.summary.should == 'Whole Foods Market Voluntarily Recalls Frozen Whole Catch Yellow Fin Tuna Steaks Due to Possible Health Risks'
        first.description.should == 'Whole Foods Market announced the recall of its Whole Catch Yellow fin Tuna Steaks (frozen) with a best by date of Dec 5th, 2010 because of possible elevated levels of histamine that may result in symptoms that generally appear within minutes to an hour after eating the affected fish.  No other Whole Foods Market, Whole Catch, 365 or 365 Organic products are affected.'
        first.food_type.should == 'food'
        first.recall.recalled_on.should == Date.parse('Mon, 05 Apr 2010')
        first.recall.organization.should == 'CDC'
        first.recall.recall_number.should_not be_nil

        last = FoodRecall.last
        last.url.should == 'http://www.fda.gov/Safety/Recalls/ucm207345.htm'
        last.summary.should == 'Golden Pacific Foods, Inc. Issues Allergy Alert for Undeclared Milk and Soy in Marco Polo Brand Shrimp Snacks'
        last.description.should == 'Chino, California  (April 2, 2010) -- Golden Pacific Foods, Inc. is recalling Marco Polo Brand Shrimp Snacks sold as Original, Onion & Garlic Flavored and Bar-B-Que Flavored, because they may contain undeclared milk and soy. People who have allergies to milk and soy run the risk of serious or life-threatening reaction if they consume these products.'
        last.food_type.should == 'food'
        last.recall.recalled_on.should == Date.parse('Sun, 04 Apr 2010')
        last.recall.organization.should=='CDC'
        last.recall.recall_number.should_not be_nil
      end

      it 'should skip recalls that have already been loaded' do
        CdcData.import_from_rss_feed('http://www2c.cdc.gov/podcasts/createrss.asp?c=146', 'food')
        CdcData.import_from_rss_feed('http://www2c.cdc.gov/podcasts/createrss.asp?c=146', 'food')
        Recall.all.size.should == 2
        FoodRecall.all.size.should == 2
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
  end
end