class Api::V1::RecallsController < ApplicationController
  include ActionController::MimeResponds
  include NewRelic::Agent::Instrumentation::ControllerInstrumentation

  def index
    @recalls = RecallSearch.recent(index_params)
    respond_to do |format|
      format.json { render json: @recalls }
      format.rss { render rss: @recalls }
    end
  end

  def search
    respond_to do |format|
      format.json { render json: RecallSearch.new(search_params) }
    end
  end

  add_transaction_tracer :index
  add_transaction_tracer :search

  private

  def index_params
    { page: @page, per_page: @per_page }
  end

  def search_params
    params.slice(:query,
                 :organization,
                 :start_date, :end_date,
                 :food_type,
                 :upc,
                 :make, :model, :year, :code,
                 :sort,
                 :hl).
        merge(page: @page,
              per_page: @per_page)
  end
end
