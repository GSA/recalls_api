require 'spec_helper'

describe Api::V1::RecallsController do
  disconnect_sunspot
  it_behaves_like 'recalls controller', [:index, :search]

  describe '#index' do
    context 'when the format is json' do
      let(:results_hash) { { total: 1 } }
      let(:search_results) { double('search results', as_json: results_hash) }

      before do
        RecallSearch.should_receive(:recent).with(page: 2, per_page: 15).and_return(search_results)
        get 'index', format: :json, page: '2', per_page: '15'
      end

      it { should respond_with(:success) }

      it 'should respond with search results' do
        response_hash = JSON.parse(response.body, symbolize_names: true)
        response_hash.should == results_hash
      end
    end

    context 'when the format is RSS' do
      before do
        RecallSearch.should_receive(:recent)
        get 'index', format: :rss
      end

      it { should respond_with(:success) }
    end
  end

  describe '#search' do
    let(:search_params) do
      { 'query' => 'baby stroller',
        'start_date' => '2012-01-01', 'end_date' => '2012-12-01',
        'food_type' => 'food',
        'upc' => '987654321',
        'make' => 'automaker1',
        'model' => 'model1',
        'year' => '2009',
        'code' => 'v',
        'page' => 2, 'per_page' => 3,
        'sort' => 'date',
        'hl' => '1' }.freeze
    end
    let(:results_hash) { { total: 1 }.freeze }
    let(:search_results) { double('search results', as_json: results_hash) }

    before do
      RecallSearch.should_receive(:new).
          with(search_params).
          and_return(search_results)

      get 'search',
          query: 'baby stroller',
          start_date: '2012-01-01', end_date: '2012-12-01',
          food_type: 'food',
          upc: '987654321',
          make: 'automaker1',
          model: 'model1',
          year: '2009',
          code: 'v',
          page: '2',
          per_page: '3',
          sort: 'date',
          hl: '1',
          format: :json
    end

    it { should respond_with(:success) }

    it 'should respond with search results' do
      response_hash = JSON.parse(response.body, symbolize_names: true)
      response_hash.should == results_hash
    end
  end
end
