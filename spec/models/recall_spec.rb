require 'spec_helper'

describe Recall do
  disconnect_sunspot

  it { should have_many(:recall_details).dependent(:destroy) }
  it { should have_many(:auto_recalls).dependent(:destroy) }
  it { should have_one(:food_recall).dependent(:destroy) }
  it { should validate_presence_of :recall_number }
  it { should validate_presence_of :organization }

  it 'should create a new instance given valid attributes' do
    Recall.create!(recall_number: '12345',
                   organization: 'CPSC',
                   y2k: 12345,
                   recalled_on: Date.parse('2010-03-01'))
  end

  describe '.search_for' do
    context 'when search raises RSolr::Error::Http' do
      it 'should return nil' do
        Recall.should_receive(:search).and_raise(RSolr::Error::Http.new({}, {}))
        Recall.search_for({query: 'stroller'}).should be_nil
      end
    end
  end

  describe '#as_json' do
    context 'when recalled_on is present' do
      let(:recall) { Recall.new(organization: 'SOME ORG', recalled_on: Date.parse('2012-01-01')) }

      it 'should assign recall_date' do
        recall.as_json[:recall_date].should == '2012-01-01'
      end
    end

    context 'when recalled_on is nil' do
      let(:recall) { Recall.new(organization: 'SOME ORG', recalled_on: nil) }

      it 'should assign recall_date to nil' do
        recall.as_json[:recall_date].should be_nil
      end
    end

    context 'when organization is FDA' do
      let(:recall) do
        Recall.new(organization: Recall::FDA,
                   recall_number: '123456',
                   recalled_on: Date.parse('2012-01-01'))
      end

      let(:food_recall) { mock_model(FoodRecall) }

      before do
        recall.should_receive(:recall_url).and_return('http://some.url.to/cdc')

        recall.should_receive(:food_recall).and_return(food_recall)
        food_recall.should_receive(:as_json).
            with(only: [:summary, :description]).
            and_return(summary: 'summary about food recall',
                       description: 'description about food recall')
      end

      it 'should populate as_json with summary and description' do
        recall.as_json.should == { organization: Recall::FDA,
                                   recall_number: '123456',
                                   recall_date: '2012-01-01',
                                   recall_url: 'http://some.url.to/cdc',
                                   summary: 'summary about food recall',
                                   description: 'description about food recall' }
      end
    end

    context 'when organization is CPSC' do
      let(:recall) do
        Recall.new(organization: Recall::CPSC,
                   recall_number: '123456',
                   recalled_on: Date.parse('2012-01-01'))
      end

      let(:recall_details_hash) do
        { manufacturer: %w(manufacturer1 manufacturer2),
          product_type: %w(product_type1 product_type2),
          description: %w(description1 description2),
          upc: %w(upc1 upc2),
          hazard: %w(hazard1 hazard2),
          country: %w(country1 country2) }
      end

      before do
        recall.should_receive(:recall_url).and_return('http://some.url.to/cpsc')
        recall.should_receive(:recall_details_hash).exactly(6).times.
            and_return(recall_details_hash)
      end

      it 'should contain details information' do
        recall.as_json.should == {
            organization: Recall::CPSC,
            recall_number: '123456',
            recall_date: '2012-01-01',
            recall_url: 'http://some.url.to/cpsc',
            manufacturers: %w(manufacturer1 manufacturer2),
            product_types: %w(product_type1 product_type2),
            descriptions: %w(description1 description2),
            upcs: %w(upc1 upc2),
            hazards: %w(hazard1 hazard2),
            countries: %w(country1 country2) }
      end
    end

    context 'when organization is NHTSA' do
      let(:recall) do
        Recall.new(organization: Recall::NHTSA,
                   recall_number: '123456',
                   recalled_on: Date.parse('2010-01-01'))
      end

      let(:auto_recall_json_hash_1) do
        { make: 'automaker1',
          model: 'model1',
          year: 2009,
          manufacturer: 'manufacturer1',
          manufacturing_begin_date: Date.parse('2010-05-01'),
          manufacturing_end_date: Date.parse('2010-05-31'),
          recalled_component_id: 'comp1',
          component_description: 'comp desc1' }
      end

      let(:auto_recall_json_hash_2) do
        { make: 'automaker2',
          model: 'model2',
          year: 2009,
          manufacturer: 'manufacturer2',
          manufacturing_begin_date: Date.parse('2010-06-01'),
          manufacturing_end_date: Date.parse('2010-06-30'),
          recalled_component_id: 'comp2',
          component_description: 'comp desc2' }
      end

      let(:recall_details_hash) do
        { manufacturer_campaign_number: %w(R06004),
          component_description: ['FUEL SYSTEM, GASOLINE:DELIVERY:FUEL PUMP'],
          manufacturer: ['MONACO COACH CORPORATION'],
          code: %w(V),
          potential_units_affected: %w(124),
          notification_date: %w(20100105),
          initiator: %w(MFR),
          report_date: %w(20100104),
          part_number: %w(571),
          federal_motor_vehicle_safety_number: %w(121),
          defect_summary: ['ON CERTAIN MOTORCYCLES, THE SIDE STAND LEGS HAVE THE POTENTIAL TO BEND OR BREAK.'],
          consequence_summary: ['IF THE FITTING LEAKS, IT COULD RESULT IN A FIRE OR EXPLOSION CAUSING BODILY HARM.'],
          corrective_summary: ['DEALERS WILL INSPECT AND REPLACE THE PUMP WITH A NEW ONE.'],
          notes: ['MONACO RECALL NO. R06004.CUSTOMERS MAY ALSO CONTACT THE NATIONAL HIGHWAY TRAFFIC SAFETY ADMINISTRATION\'S VEHICLE SAFETY HOTLINE AT 1-888-327-4236.'],
          recall_subject: ['MCKENZIE/DUNE CHASER'] }
      end

      before do
        recall.should_receive(:recall_url).and_return('http://some.url.to/nhtsa')
        auto_recall_1 = mock_model(AutoRecall)
        auto_recall_2 = mock_model(AutoRecall)
        recall.should_receive(:auto_recalls).and_return([auto_recall_1, auto_recall_2])
        auto_recall_1.should_receive(:as_json).and_return(auto_recall_json_hash_1)
        auto_recall_2.should_receive(:as_json).and_return(auto_recall_json_hash_2)
        recall.should_receive(:recall_details_hash).at_least(:once).
            and_return(recall_details_hash)
      end

      it 'should contain detail information' do
        recall.as_json.should == {
            organization: Recall::NHTSA,
            recall_number: '123456',
            recall_date: '2010-01-01',
            recall_url: 'http://some.url.to/nhtsa',
            records: [{ make: 'automaker1',
                        model: 'model1',
                        year: 2009,
                        manufacturer: 'manufacturer1',
                        manufacturing_begin_date: Date.parse('2010-05-01'),
                        manufacturing_end_date: Date.parse('2010-05-31'),
                        recalled_component_id: 'comp1',
                        component_description: 'comp desc1' },
                      { make: 'automaker2',
                        model: 'model2',
                        year: 2009,
                        manufacturer: 'manufacturer2',
                        manufacturing_begin_date: Date.parse('2010-06-01'),
                        manufacturing_end_date: Date.parse('2010-06-30'),
                        recalled_component_id: 'comp2',
                        component_description: 'comp desc2' }],
            manufacturer_campaign_number: 'R06004',
            component_description: 'FUEL SYSTEM, GASOLINE:DELIVERY:FUEL PUMP',
            manufacturer: 'MONACO COACH CORPORATION',
            code: 'V',
            potential_units_affected: '124',
            notification_date: '20100105',
            initiator: 'MFR',
            report_date: '20100104',
            part_number: '571',
            federal_motor_vehicle_safety_number: '121',
            defect_summary: 'ON CERTAIN MOTORCYCLES, THE SIDE STAND LEGS HAVE THE POTENTIAL TO BEND OR BREAK.',
            consequence_summary: 'IF THE FITTING LEAKS, IT COULD RESULT IN A FIRE OR EXPLOSION CAUSING BODILY HARM.',
            corrective_summary: 'DEALERS WILL INSPECT AND REPLACE THE PUMP WITH A NEW ONE.',
            notes: 'MONACO RECALL NO. R06004.CUSTOMERS MAY ALSO CONTACT THE NATIONAL HIGHWAY TRAFFIC SAFETY ADMINISTRATION\'S VEHICLE SAFETY HOTLINE AT 1-888-327-4236.',
            recall_subject: 'MCKENZIE/DUNE CHASER' }
      end
    end
  end

  describe '#recall_url' do
    context 'when organization is a food/drug agency' do
      let(:recall) { Recall.new(organization: 'FDA') }

      before do
        food_recall = mock_model(FoodRecall, url: 'http://www.fda.gov/Safety/Recalls/ucm207477.htm')
        recall.should_receive(:food_recall).and_return(food_recall)
      end

      it 'should return food_recall.url' do
        recall.recall_url.should == 'http://www.fda.gov/Safety/Recalls/ucm207477.htm'
      end
    end

    context 'when organization is CPSC' do
      subject { Recall.new(recall_number: '12345', organization: 'CPSC').recall_url }
      it { should == 'http://www.cpsc.gov/cpscpub/prerel/prhtml12/12345.html' }
    end

    context 'when organization is NHTSA' do
      subject { Recall.new(recall_number: '12345', organization: 'NHTSA').recall_url }
      it { should == 'http://www-odi.nhtsa.dot.gov/recalls/recallresults.cfm?start=1&SearchType=QuickSearch&rcl_ID=12345&summary=true&PrintVersion=YES' }
    end
  end

  describe '#summary' do
    context 'when organization is a food/drug agency' do
      subject(:recall) { Recall.new(organization: Recall::FDA) }

      before do
        recall.should_receive(:food_recall).
            and_return(mock_model(FoodRecall, summary: 'a summary about this recall'))
      end

      its(:summary) { should == 'a summary about this recall' }
    end

    context 'when organization is CPSC' do
      subject(:recall) { Recall.new(organization: 'CPSC') }

      before do
        recall.should_receive(:recall_details_hash).
            twice.
            and_return({ description: %w(description1 description2) })
      end

      its(:summary) { should == 'description1, description2' }
    end

    context 'when organization is NHTSA' do
      subject(:recall) { Recall.new(organization: 'NHTSA') }

      before do
        recall.should_receive(:recall_details_hash).
            at_least(:twice).
            and_return({ component_description: %w(component_desc1),
                         manufacturer: %w(manufacturer1) })
      end

      its(:summary) { should == 'component_desc1 FROM manufacturer1' }
    end

    context 'when summary is not present' do
      subject(:recall) { Recall.new(organization: 'FOO') }
      its(:summary) { should == 'Click here to see products' }
    end
  end

  describe '#description' do
    context 'when organization is a food/drug agency' do
      subject(:recall) { Recall.new(organization: Recall::USDA) }

      before do
        recall.should_receive(:food_recall).
            and_return(mock_model(FoodRecall, description: 'a description about this recall'))
      end

      its(:description) { should == 'a description about this recall' }
    end

    context 'when organization is CPSC' do
      subject(:recall) { Recall.new(organization: 'CPSC') }

      before do
        recall.should_receive(:recall_details_hash).
            and_return({ product_type: %w(product_type1 product_type2) })
      end

      its(:description) { should == 'product_type1, product_type2' }
    end

    context 'when organization is NHTSA' do
      subject(:recall) { Recall.new(organization: 'NHTSA') }

      before do
        recall.should_receive(:auto_recalls).
            and_return([mock_model(AutoRecall, make: 'make1', model: 'model1', year: 2011),
                        mock_model(AutoRecall, make: 'make1', model: 'model1', year: 2012),
                        mock_model(AutoRecall, make: 'make1', model: 'model2', year: 2013),
                        mock_model(AutoRecall, make: 'make2', model: 'model3', year: 2013)])
      end

      its(:description) { should == 'Recalls for: make1 / model1, make1 / model2, make2 / model3' }
    end
  end
end
