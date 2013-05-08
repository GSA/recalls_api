require 'spec_helper'
require 'nokogiri'

describe 'Recalls API V1' do
  before(:all) do
    Recall.create!(organization: 'FDA',
                   recall_number: Digest::MD5.hexdigest('http://www.fda.gov/Safety/Recalls/ucm215921.htm')[0, 10],
                   recalled_on: Date.parse('2010-04-03')) do |r|
      r.build_food_recall(description: 'Drug Recall description',
                          food_type: 'drug',
                          summary: 'Drug Recall summary',
                          url: 'http://www.fda.gov/Safety/Recalls/ucm215921.htm')
    end

    Recall.create!(organization: 'FDA',
                   recall_number: Digest::MD5.hexdigest('http://www.fda.gov/Safety/Recalls/ucm207477.htm')[0, 10],
                   recalled_on: Date.parse('2010-04-05')) do |r|
      r.build_food_recall(description: 'Food Recall description',
                          food_type: 'food',
                          summary: 'Food Recall summary',
                          url: 'http://www.fda.gov/Safety/Recalls/ucm207477.htm')
    end

    Recall.create!(organization: 'USDA',
                   recall_number: Digest::MD5.hexdigest('http://www.fsis.usda.gov/News_&_Events/Recall_028_2013_Expanded/index.asp')[0, 10],
                   recalled_on: Date.parse('2013-04-12')) do |r|
      r.build_food_recall(description: 'USDA Food Recall description',
                          food_type: 'food',
                          summary: 'USDA Food Recall summary',
                          url: 'http://www.fsis.usda.gov/News_&_Events/Recall_028_2013_Expanded/index.asp')
    end

    10.upto(18) do |i|
      Recall.create!(organization: 'FDA',
                     recall_number: Digest::MD5.hexdigest("http://www.fda.gov/Safety/Recalls/ucm2159#{i}.htm")[0, 10],
                     recalled_on: Date.parse("2005-04-#{i}")) do |r|
        r.build_food_recall(description: "Drug Recall description #{i}",
                            food_type: 'drug',
                            summary: "Drug Recall summary #{i}",
                            url: "http://www.fda.gov/Safety/Recalls/ucm2159#{i}.htm")
      end
    end

    Recall.create!(organization: 'CPSC',
                   recall_number: '12345',
                   y2k: 12345,
                   recalled_on: Date.parse('2010-03-01')) do |r|
      r.recall_details.build(detail_type: 'Manufacturer', detail_value: 'Acme Corp')
      r.recall_details.build(detail_type: 'ProductType', detail_value: 'Dangerous Stuff')
      r.recall_details.build(detail_type: 'Description', detail_value: 'Baby Stroller can be dangerous to children')
      r.recall_details.build(detail_type: 'Hazard', detail_value: 'Horrible Choking')
      r.recall_details.build(detail_type: 'Country', detail_value: 'United States')
      r.recall_details.build(detail_type: 'UPC', detail_value: '0123456789')
    end

    Recall.create!(organization: 'CPSC',
                   recall_number: '10187',
                   y2k: 110187,
                   recalled_on: Date.parse('2010-04-01')) do |r|
      r.recall_details.build(detail_type: 'Manufacturer', detail_value: 'Crate & Barrel')
      r.recall_details.build(detail_type: 'ProductType', detail_value: 'Bottles (Sports/Water/Thermos)')
      r.recall_details.build(detail_type: 'Description', detail_value: 'Glass Water Bottles')
      r.recall_details.build(detail_type: 'Hazard', detail_value: 'Laceration')
      r.recall_details.build(detail_type: 'Country', detail_value: 'China')
      r.recall_details.build(detail_type: 'UPC', detail_value: 'AA987654321')
      r.recall_details.build(detail_type: 'UPC', detail_value: 'BB876543219')
    end

    Recall.create!(organization: 'NHTSA',
                   recall_number: '123456',
                   recalled_on: Date.parse('2010-01-01')) do |r|
      r.auto_recalls.build(make: 'automaker1',
                           model: 'model1',
                           year: 2009,
                           manufacturer: 'manufacturer1',
                           manufacturing_begin_date: Date.parse('2009-05-01'),
                           manufacturing_end_date: Date.parse('2009-05-31'),
                           recalled_component_id: 'comp1',
                           component_description: 'comp desc1')

      r.auto_recalls.build(make: 'automaker2',
                           model: 'model2',
                           manufacturer: 'manufacturer2',
                           manufacturing_begin_date: Date.parse('2009-06-01'),
                           manufacturing_end_date: Date.parse('2009-06-30'),
                           recalled_component_id: 'comp2',
                           component_description: 'comp desc2')

      { manufacturer_campaign_number: 'R06004',
        component_description: 'FUEL SYSTEM, GASOLINE:DELIVERY:FUEL PUMP compound',
        manufacturer: 'MONACO COACH CORPORATION',
        code: 'V',
        potential_units_affected: '124',
        notification_date: '20100105',
        initiator: 'MFR',
        report_date: '20100104',
        part_number: '571',
        federal_motor_vehicle_safety_number: '121',
        defect_summary: 'fuel pump defect summary',
        consequence_summary: 'fuel pump consequence summary',
        corrective_summary: 'fuel pump corrective summary',
        notes: 'fuel pump notes',
        recall_subject: 'MCKENZIE/DUNE CHASER' }.each do |detail_type, detail_value|
        r.recall_details.build(detail_type: detail_type, detail_value: detail_value)
      end
    end

    Sunspot.commit
  end

  after(:all) do
    Recall.destroy_all
    Sunspot.commit
  end

  describe 'GET /api/recalls' do
    context 'when format is JSON' do
      before { get '/recent.json' }

      it 'should respond with status code 200' do
        response.status.should == 200
      end

      it 'should respond with content type json' do
        response.content_type.should == :json
      end

      it 'should return recent recalls sorted by date' do
        recent_hash = JSON.parse(response.body, symbolize_names: true)
        recent_hash[:success][:total].should == 15

        item = recent_hash[:success][:results][0]
        item.should == { organization: 'USDA',
                         recall_number: 'b4e5a49f9c',
                         recall_date: '2013-04-12',
                         recall_url: 'http://www.fsis.usda.gov/News_&_Events/Recall_028_2013_Expanded/index.asp',
                         description: 'USDA Food Recall description',
                         summary: 'USDA Food Recall summary' }

        item = recent_hash[:success][:results][1]
        item.should == { organization: 'FDA',
                         recall_number: '2ef7340756',
                         recall_date: '2010-04-05',
                         recall_url: 'http://www.fda.gov/Safety/Recalls/ucm207477.htm',
                         description: 'Food Recall description',
                         summary: 'Food Recall summary' }

        item = recent_hash[:success][:results][2]
        item.should == { organization: 'FDA',
                         recall_number: '7de417aef9',
                         recall_date: '2010-04-03',
                         recall_url: 'http://www.fda.gov/Safety/Recalls/ucm215921.htm',
                         description: 'Drug Recall description', summary: 'Drug Recall summary' }

        item = recent_hash[:success][:results][3]
        item.should == { organization: 'CPSC',
                         recall_number: '10187',
                         recall_date: '2010-04-01',
                         recall_url: 'http://www.cpsc.gov/cpscpub/prerel/prhtml10/10187.html',
                         manufacturers: ['Crate & Barrel'],
                         product_types: ['Bottles (Sports/Water/Thermos)'],
                         descriptions: ['Glass Water Bottles'],
                         upcs: %w(AA987654321 BB876543219),
                         hazards: %w(Laceration),
                         countries: %w(China) }

        item = recent_hash[:success][:results][4]
        item.should == { organization: 'CPSC',
                         recall_number: '12345',
                         recall_date: '2010-03-01',
                         recall_url: 'http://www.cpsc.gov/cpscpub/prerel/prhtml12/12345.html',
                         manufacturers: ['Acme Corp'],
                         product_types: ['Dangerous Stuff'],
                         descriptions: ['Baby Stroller can be dangerous to children'],
                         upcs: %w(0123456789),
                         hazards: ['Horrible Choking'],
                         countries: ['United States'] }

        item = recent_hash[:success][:results][5]
        item.should == {
            organization: Recall::NHTSA,
            recall_number: '123456',
            recall_date: '2010-01-01',
            recall_url: 'http://www-odi.nhtsa.dot.gov/recalls/recallresults.cfm?start=1&SearchType=QuickSearch&rcl_ID=123456&summary=true&PrintVersion=YES',
            records: [{ component_description: 'comp desc1',
                        make: 'automaker1',
                        manufacturer: 'manufacturer1',
                        manufacturing_begin_date: '2009-05-01',
                        manufacturing_end_date: '2009-05-31',
                        model: 'model1',
                        recalled_component_id: 'comp1',
                        year: 2009 },
                      { component_description: 'comp desc2',
                        make: 'automaker2',
                        manufacturer: 'manufacturer2',
                        manufacturing_begin_date: '2009-06-01',
                        manufacturing_end_date: '2009-06-30',
                        model: 'model2',
                        recalled_component_id: 'comp2',
                        year: nil }],
            manufacturer_campaign_number: 'R06004',
            component_description: 'FUEL SYSTEM, GASOLINE:DELIVERY:FUEL PUMP compound',
            manufacturer: 'MONACO COACH CORPORATION',
            code: 'V',
            potential_units_affected: '124',
            notification_date: '20100105',
            initiator: 'MFR',
            report_date: '20100104',
            part_number: '571',
            federal_motor_vehicle_safety_number: '121',
            defect_summary: 'fuel pump defect summary',
            consequence_summary: 'fuel pump consequence summary',
            corrective_summary: 'fuel pump corrective summary',
            notes: 'fuel pump notes',
            recall_subject: 'MCKENZIE/DUNE CHASER' }
      end
    end

    context 'when format is RSS' do
      def parse_items(feed)
        feed.xpath('//item').collect do |item|
          { link: item.xpath('./link').inner_text,
            guid: item.xpath('./guid').inner_text,
            title: item.xpath('./title').inner_text,
            pub_date: item.xpath('./pubDate').inner_text,
            description: item.xpath('./description').inner_text }
        end
      end

      before { get '/recent.rss' }

      it 'should respond with status code 200' do
        response.status.should == 200
      end

      it 'should respond with content type rss' do
        response.content_type.should == :rss
      end

      it 'should return recent recalls sorted by date' do
        recent_feed = Nokogiri::XML(response.body)
        items = parse_items(recent_feed)
        items.count.should == 10

        item = items[0]
        item[:title].should == 'USDA Food Recall summary'
        item[:description].should == 'USDA Food Recall description'
        item[:link].should == 'http://www.fsis.usda.gov/News_&_Events/Recall_028_2013_Expanded/index.asp'
        item[:pub_date].should == 'Fri, 12 Apr 2013 00:00:00 +0000'
        item[:guid].should == 'http://www.fsis.usda.gov/News_&_Events/Recall_028_2013_Expanded/index.asp'

        item = items[1]
        item[:title].should == 'Food Recall summary'
        item[:description].should == 'Food Recall description'
        item[:link].should == 'http://www.fda.gov/Safety/Recalls/ucm207477.htm'
        item[:pub_date].should == 'Mon, 05 Apr 2010 00:00:00 +0000'
        item[:guid].should == 'http://www.fda.gov/Safety/Recalls/ucm207477.htm'

        item = items[2]
        item[:title].should == 'Drug Recall summary'
        item[:description].should == 'Drug Recall description'
        item[:link].should == 'http://www.fda.gov/Safety/Recalls/ucm215921.htm'
        item[:pub_date].should == 'Sat, 03 Apr 2010 00:00:00 +0000'
        item[:guid].should == 'http://www.fda.gov/Safety/Recalls/ucm215921.htm'

        item = items[3]
        item[:title].should == 'Glass Water Bottles'
        item[:description].should == 'Bottles (Sports/Water/Thermos)'
        item[:link].should == 'http://www.cpsc.gov/cpscpub/prerel/prhtml10/10187.html'
        item[:pub_date].should == 'Thu, 01 Apr 2010 00:00:00 +0000'
        item[:guid].should == 'http://www.cpsc.gov/cpscpub/prerel/prhtml10/10187.html'

        item = items[4]
        item[:title].should == 'Baby Stroller can be dangerous to children'
        item[:description].should == 'Dangerous Stuff'
        item[:link].should == 'http://www.cpsc.gov/cpscpub/prerel/prhtml12/12345.html'
        item[:pub_date].should == 'Mon, 01 Mar 2010 00:00:00 +0000'
        item[:guid].should == 'http://www.cpsc.gov/cpscpub/prerel/prhtml12/12345.html'

        item = items[5]
        item[:title].should == 'FUEL SYSTEM, GASOLINE:DELIVERY:FUEL PUMP compound FROM MONACO COACH CORPORATION'
        item[:description].should == 'Recalls for: automaker1 / model1, automaker2 / model2'
        item[:link].should == 'http://www-odi.nhtsa.dot.gov/recalls/recallresults.cfm?start=1&SearchType=QuickSearch&rcl_ID=123456&summary=true&PrintVersion=YES'
        item[:pub_date].should == 'Fri, 01 Jan 2010 00:00:00 +0000'
        item[:guid].should == 'http://www-odi.nhtsa.dot.gov/recalls/recallresults.cfm?start=1&SearchType=QuickSearch&rcl_ID=123456&summary=true&PrintVersion=YES'
      end
    end
  end

  describe 'GET /search.json' do
    context 'when format is JSON' do
      context 'when searching for food data with query' do
        before { get '/search.json', organization: 'FDA', query: 'food' }

        it 'should respond with status code 200' do
          response.status.should == 200
        end

        it 'should respond with content type json' do
          response.content_type.should == :json
        end

        it 'should return with CDC data' do
          cdc_hash = JSON.parse(response.body, symbolize_names: true)
          cdc_hash[:success][:total].should == 1

          item = cdc_hash[:success][:results].first
          item.should == { organization: 'FDA',
                           recall_number: '2ef7340756',
                           recall_date: '2010-04-05',
                           recall_url: 'http://www.fda.gov/Safety/Recalls/ucm207477.htm',
                           description: 'Food Recall description',
                           summary: 'Food Recall summary' }
        end
      end

      context 'when searching for CDC data with highlighting option' do
        context 'when searching for CDC data with query' do
          before { get '/search.json', organization: 'cdc', query: 'food', hl: '1' }

          it 'should return with highlighted CDC data' do
            cdc_hash = JSON.parse(response.body, symbolize_names: true)
            cdc_hash[:success][:total].should == 2

            item = cdc_hash[:success][:results].first
            item.should == { organization: 'FDA',
                             recall_number: '2ef7340756',
                             recall_date: '2010-04-05',
                             recall_url: 'http://www.fda.gov/Safety/Recalls/ucm207477.htm',
                             description: "\uE000Food\uE001 Recall description",
                             summary: "\uE000Food\uE001 Recall summary" }

            item = cdc_hash[:success][:results].last
            item.should == { organization: 'USDA',
                             recall_number: 'b4e5a49f9c',
                             recall_date: '2013-04-12',
                             recall_url: 'http://www.fsis.usda.gov/News_&_Events/Recall_028_2013_Expanded/index.asp',
                             description: "USDA \uE000Food\uE001 Recall description",
                             summary: "USDA \uE000Food\uE001 Recall summary" }
          end
        end
      end

      context 'when searching for CPSC data with query' do
        before { get '/search.json', organization: 'cpsc', query: 'acme' }

        it 'should respond with status code 200' do
          response.status.should == 200
        end

        it 'should respond with content type json' do
          response.content_type.should == :json
        end

        it 'should return with CPSC data' do
          cpsc_hash = JSON.parse(response.body, symbolize_names: true)
          cpsc_hash[:success][:total].should == 1

          item = cpsc_hash[:success][:results].first
          item.should == { organization: 'CPSC',
                           recall_number: '12345',
                           recall_date: '2010-03-01',
                           recall_url: 'http://www.cpsc.gov/cpscpub/prerel/prhtml12/12345.html',
                           manufacturers: ['Acme Corp'],
                           product_types: ['Dangerous Stuff'],
                           descriptions: ['Baby Stroller can be dangerous to children'],
                           upcs: %w(0123456789),
                           hazards: ['Horrible Choking'],
                           countries: ['United States'] }
        end
      end

      context 'when searching for CPSC data with highlighting option' do
        before { get '/search.json', organization: 'cpsc', query: 'horrible stroller', hl: '1' }

        it 'should return with highlighted CPSC data' do
          cpsc_hash = JSON.parse(response.body, symbolize_names: true)
          cpsc_hash[:success][:total].should == 1

          item = cpsc_hash[:success][:results].first
          item.should == { organization: 'CPSC',
                           recall_number: '12345',
                           recall_date: '2010-03-01',
                           recall_url: 'http://www.cpsc.gov/cpscpub/prerel/prhtml12/12345.html',
                           manufacturers: ['Acme Corp'],
                           product_types: ['Dangerous Stuff'],
                           descriptions: ["Baby \uE000Stroller\uE001 can be dangerous to children"],
                           upcs: %w(0123456789),
                           hazards: ["\uE000Horrible\uE001 Choking"],
                           countries: ['United States'] }
        end
      end

      context 'when searching for NHTSA data with query' do
        before { get '/search.json', organization: 'nhtsa', query: 'fuel pump' }

        it 'should respond with status code 200' do
          response.status.should == 200
        end

        it 'should respond with content type json' do
          response.content_type.should == :json
        end

        it 'should return with NHTSA data' do
          nhtsa_hash = JSON.parse(response.body, symbolize_names: true)
          nhtsa_hash[:success][:total].should == 1

          item = nhtsa_hash[:success][:results].first
          item.should == {
              organization: Recall::NHTSA,
              recall_number: '123456',
              recall_date: '2010-01-01',
              recall_url: 'http://www-odi.nhtsa.dot.gov/recalls/recallresults.cfm?start=1&SearchType=QuickSearch&rcl_ID=123456&summary=true&PrintVersion=YES',
              records: [{ component_description: 'comp desc1',
                          make: 'automaker1',
                          manufacturer: 'manufacturer1',
                          manufacturing_begin_date: '2009-05-01',
                          manufacturing_end_date: '2009-05-31',
                          model: 'model1',
                          recalled_component_id: 'comp1',
                          year: 2009 },
                        { component_description: 'comp desc2',
                          make: 'automaker2',
                          manufacturer: 'manufacturer2',
                          manufacturing_begin_date: '2009-06-01',
                          manufacturing_end_date: '2009-06-30',
                          model: 'model2',
                          recalled_component_id: 'comp2',
                          year: nil }],
              manufacturer_campaign_number: 'R06004',
              component_description: 'FUEL SYSTEM, GASOLINE:DELIVERY:FUEL PUMP compound',
              manufacturer: 'MONACO COACH CORPORATION',
              code: 'V',
              potential_units_affected: '124',
              notification_date: '20100105',
              initiator: 'MFR',
              report_date: '20100104',
              part_number: '571',
              federal_motor_vehicle_safety_number: '121',
              defect_summary: 'fuel pump defect summary',
              consequence_summary: 'fuel pump consequence summary',
              corrective_summary: 'fuel pump corrective summary',
              notes: 'fuel pump notes',
              recall_subject: 'MCKENZIE/DUNE CHASER' }
        end
      end

      context 'when searching for NHTSA data with highlighting option' do
        before { get '/search.json', organization: 'nhtsa', query: 'fuel pump', hl: '1' }

        it 'should return with NHTSA data' do
          nhtsa_hash = JSON.parse(response.body, symbolize_names: true)
          nhtsa_hash[:success][:total].should == 1

          item = nhtsa_hash[:success][:results].first
          item.should == {
              organization: Recall::NHTSA,
              recall_number: '123456',
              recall_date: '2010-01-01',
              recall_url: 'http://www-odi.nhtsa.dot.gov/recalls/recallresults.cfm?start=1&SearchType=QuickSearch&rcl_ID=123456&summary=true&PrintVersion=YES',
              records: [{ component_description: 'comp desc1',
                          make: 'automaker1',
                          manufacturer: 'manufacturer1',
                          manufacturing_begin_date: '2009-05-01',
                          manufacturing_end_date: '2009-05-31',
                          model: 'model1',
                          recalled_component_id: 'comp1',
                          year: 2009 },
                        { component_description: 'comp desc2',
                          make: 'automaker2',
                          manufacturer: 'manufacturer2',
                          manufacturing_begin_date: '2009-06-01',
                          manufacturing_end_date: '2009-06-30',
                          model: 'model2',
                          recalled_component_id: 'comp2',
                          year: nil }],
              manufacturer_campaign_number: 'R06004',
              component_description: "\uE000FUEL\uE001 SYSTEM, GASOLINE:DELIVERY:\uE000FUEL\uE001 \uE000PUMP\uE001 compound",
              manufacturer: 'MONACO COACH CORPORATION',
              code: 'V',
              potential_units_affected: '124',
              notification_date: '20100105',
              initiator: 'MFR',
              report_date: '20100104',
              part_number: '571',
              federal_motor_vehicle_safety_number: '121',
              defect_summary: "\uE000fuel\uE001 \uE000pump\uE001 defect summary",
              consequence_summary: "\uE000fuel\uE001 \uE000pump\uE001 consequence summary",
              corrective_summary: "\uE000fuel\uE001 \uE000pump\uE001 corrective summary",
              notes: "\uE000fuel\uE001 \uE000pump\uE001 notes",
              recall_subject: 'MCKENZIE/DUNE CHASER' }
        end
      end

      context 'when searching for recalls data with start date' do
        before { get '/search.json', start_date: '2010-04-01' }

        it 'should return with recalls with start_date' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 4
          recalls_hash[:success][:results].count.should == 4
        end
      end

      context 'when searching for recalls data with end date' do
        before { get '/search.json', end_date: '2006-01-01' }

        it 'should return with recalls with start_date' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 9
          recalls_hash[:success][:results].count.should == 9
        end
      end

      context 'when searching for recalls with page and per_page' do
        before { get '/search.json', page: '2', per_page: '8' }

        it 'should return auto recalls with matching year' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 15
          recalls_hash[:success][:results].count.should == 7
        end
      end

      context 'when searching for recalls with sort by date' do
        before { get '/search.json', sort: 'date' }

        it 'should return the latest recall' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:results].first[:recall_date].should == '2013-04-12'
        end
      end

      context 'when searching for food recalls with food_type' do
        before { get '/search.json', food_type: 'food' }

        it 'should return with recalls with start_date' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 2
          recalls_hash[:success][:results].first[:summary].should == 'Food Recall summary'
          recalls_hash[:success][:results].last[:summary].should == 'USDA Food Recall summary'
        end
      end

      context 'when searching for product recalls with UPC' do
        before { get '/search.json', upc: 'bb876543219' }

        it 'should return with recalls with start_date' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 1
          recalls_hash[:success][:results].first[:recall_number].should == '10187'
        end
      end

      context 'when searching for product recalls with manufacturer' do
        before { get '/search.json', query: 'crate & barrel' }

        it 'should return matching recall' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 1
          recalls_hash[:success][:results].first[:recall_number].should == '10187'
        end
      end

      context 'when searching for product recalls with product type' do
        before { get '/search.json', query: 'bottle' }

        it 'should return matching recall' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 1
          recalls_hash[:success][:results].first[:recall_number].should == '10187'
        end
      end

      context 'when searching for product recalls with description' do
        before { get '/search.json', query: 'babies' }

        it 'should return matching recall' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 1
          recalls_hash[:success][:results].first[:recall_number].should == '12345'
        end
      end

      context 'when searching for product recalls with hazard' do
        before { get '/search.json', query: 'choke' }

        it 'should return matching recall' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 1
          recalls_hash[:success][:results].first[:recall_number].should == '12345'
        end
      end

      context 'when searching for product recalls with country' do
        before { get '/search.json', query: 'china' }

        it 'should return matching recall' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 1
          recalls_hash[:success][:results].first[:recall_number].should == '10187'
        end
      end

      context 'when searching for auto recalls with make' do
        before { get '/search.json', make: 'AUTOmaker2' }

        it 'should return with recalls with matching make' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 1
          recalls_hash[:success][:results].first[:organization].should == 'NHTSA'
          recalls_hash[:success][:results].first[:recall_number].should == '123456'
          recalls_hash[:success][:results].first[:records].last[:make].should == 'automaker2'
        end
      end

      context 'when searching for auto recalls with model' do
        before { get '/search.json', model: 'MODEL1' }

        it 'should return auto recalls with matching model' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 1
          recalls_hash[:success][:results].first[:organization].should == 'NHTSA'
          recalls_hash[:success][:results].first[:recall_number].should == '123456'
          recalls_hash[:success][:results].first[:records].first[:model].should == 'model1'
        end
      end

      context 'when searching for auto recalls with year' do
        before { get '/search.json', year: '2009' }

        it 'should return auto recalls with matching year' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 1
          recalls_hash[:success][:results].first[:organization].should == 'NHTSA'
          recalls_hash[:success][:results].first[:recall_number].should == '123456'
          recalls_hash[:success][:results].first[:records].first[:year].should == 2009
        end
      end

      context 'when searching for auto recalls with code' do
        before { get '/search.json', code: 'v' }

        it 'should return auto recalls with matching year' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 1
          recalls_hash[:success][:results].first[:organization].should == 'NHTSA'
          recalls_hash[:success][:results].first[:recall_number].should == '123456'
          recalls_hash[:success][:results].first[:records].first[:year].should == 2009
        end
      end

      context 'when searching for auto recalls with component description' do
        before { get '/search.json', query: 'compounded' }

        it 'should return matching auto recall' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 1
          recalls_hash[:success][:results].first[:recall_number].should == '123456'
        end
      end

      context 'when searching for auto recalls with defect summary' do
        before { get '/search.json', query: 'defective' }

        it 'should return matching auto recall' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 1
          recalls_hash[:success][:results].first[:recall_number].should == '123456'
        end
      end

      context 'when searching for auto recalls with consequence summary' do
        before { get '/search.json', query: 'consequent' }

        it 'should return matching auto recall' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 1
          recalls_hash[:success][:results].first[:recall_number].should == '123456'
        end
      end

      context 'when searching for auto recalls with corrective summary' do
        before { get '/search.json', query: 'correction' }

        it 'should return matching auto recall' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 1
          recalls_hash[:success][:results].first[:recall_number].should == '123456'
        end
      end

      context 'when searching for auto recalls with notes' do
        before { get '/search.json', query: 'noted' }

        it 'should return matching auto recall' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 1
          recalls_hash[:success][:results].first[:recall_number].should == '123456'
        end
      end

      context 'when searching with Solr local params' do
        before { get '/search.json', query: '{!rows=3} drug', per_page: '1' }

        it 'should ignore Solr local params' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 10
          recalls_hash[:success][:results].count.should == 1
        end
      end

      context 'when query contains invalid Lucene tokens' do
        before { get '/search.json', query: '"drug"+ -', per_page: '1' }

        it 'should ignore Solr local params' do
          recalls_hash = JSON.parse(response.body, symbolize_names: true)
          recalls_hash[:success][:total].should == 10
          recalls_hash[:success][:results].count.should == 1
        end
      end
    end
  end
end
