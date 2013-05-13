class ApplicationController < ActionController::API
  DEFAULT_PAGE = 1.freeze
  VALID_PAGE_RANGE = (1..20).freeze
  DEFAULT_PER_PAGE = 10.freeze
  VALID_PER_PAGE_RANGE = (1..50).freeze

  before_filter :validate_params

  def validate_params
    @page = params[:page].present? ? (params[:page].to_i rescue DEFAULT_PAGE) : DEFAULT_PAGE
    @per_page = params[:per_page].present? ? (params[:per_page].to_i rescue DEFAULT_PER_PAGE) : DEFAULT_PER_PAGE
    unless VALID_PAGE_RANGE.include?(@page) && VALID_PER_PAGE_RANGE.include?(@per_page)
      render text: 'Bad Request', status: 400
    end
  end
end