class Recall < ActiveRecord::Base
  attr_accessible :organization, :recall_number, :recalled_on, :y2k
  has_many :recall_details, dependent: :destroy
  has_many :auto_recalls, dependent: :destroy
  has_one :food_recall, dependent: :destroy

  validates_presence_of :organization, :recall_number

  CDC = 'CDC'.freeze
  CPSC = 'CPSC'.freeze
  NHTSA = 'NHTSA'.freeze

  VALID_ORGANIZATIONS = [CDC, CPSC, NHTSA].freeze

  CDC_HIGHLIGHTED_FIELDS = %w(summary description).freeze

  CPSC_DETAIL_TYPES = %w(Manufacturer ProductType Description UPC Hazard Country).freeze
  CPSC_FULL_TEXT_SEARCH_FIELDS = %w(Manufacturer ProductType Description Hazard Country).freeze
  CPSC_HIGHLIGHTED_FIELDS = [:description, :hazard].freeze

  NHTSA_DETAIL_FIELDS = {
      'ManufacturerCampaignNumber' => 5,
      'ComponentDescription' => 6,
      'Manufacturer' => 7,
      'Code' => 10,
      'PotentialUnitsAffected' => 11,
      'NotificationDate' => 12,
      'Initiator' => 13,
      'ReportDate' => 15,
      'PartNumber' => 17,
      'FederalMotorVehicleSafetyNumber' => 18,
      'DefectSummary' => 19,
      'ConsequenceSummary' => 20,
      'CorrectiveSummary' => 21,
      'Notes' => 22,
      'RecallSubject' => 25
  }.freeze

  NHTSA_FULL_TEXT_SEARCH_FIELDS = %w(ComponentDescription DefectSummary ConsequenceSummary CorrectiveSummary Notes).freeze
  NHTSA_HIGHLIGHTED_FIELDS = NHTSA_FULL_TEXT_SEARCH_FIELDS.collect { |f| f.underscore.to_sym }.freeze

  searchable do
    string :organization
    string :recall_number
    time :recalled_on

    boost do |recall|
      boost_value = Time.parse(recall.recalled_on.to_s).to_i if recall.recalled_on.present?
      boost_value unless recall.recalled_on.blank?
    end

    integer :recall_year do |recall|
      recall.recalled_on.year unless recall.recalled_on.blank?
    end

    string :upc, multiple: true, as: 'upc_sm_ci' do
      recall_details_hash[:upc] unless recall_details_hash[:upc].blank?
    end

    CPSC_FULL_TEXT_SEARCH_FIELDS.each do |detail_type|
      key = detail_type.underscore.to_sym
      text key, stored: true do
        recall_details_hash[key] if cpsc?
      end
    end

    string :make, multiple: true, as: 'make_sm_ci' do
      auto_recalls.map { |auto_recall| auto_recall.make } if nhtsa?
    end

    string :model, multiple: true, as: 'model_sm_ci' do
      auto_recalls.map { |auto_recall| auto_recall.model } if nhtsa?
    end

    integer :year, multiple: true do
      auto_recalls.map { |auto_recall| auto_recall.year }.compact.uniq if nhtsa?
    end

    string :code, as: 'code_s_ci' do
      recall_details_hash[:code].first if nhtsa? && recall_details_hash[:code]
    end

    NHTSA_FULL_TEXT_SEARCH_FIELDS.each do |detail_type|
      key = detail_type.underscore.to_sym
      text key, stored: true do
        recall_details_hash[key].first if nhtsa? && recall_details_hash[key]
      end
    end

    text :food_recall_summary, stored: true do
      food_recall.summary if cdc?
    end

    text :food_recall_description, stored: true do
      food_recall.description if cdc?
    end

    string :food_type do
      food_recall.food_type if cdc?
    end
  end

  class << self
    include QueryPreprocessor
  end

  def self.search_for(options = {})
    query = preprocess(options[:query]) || nil
    page = options[:page].to_i
    page = 1 unless (1..20).include?(page)

    per_page = options[:per_page].to_i
    per_page = 10 unless (1..50).include?(per_page)

    instrument_query = { model: self.name, term: query }.
        merge(options.except(:query, :page, :per_page))

    ActiveSupport::Notifications.instrument('solr_search.usagov', query: instrument_query) do
      search do
        fulltext query do
          highlight
        end

        with(:organization, options[:organization].upcase) unless options[:organization].blank?

        # date range fields
        with(:recalled_on).greater_than(options[:start_date]) if options[:start_date].present?
        with(:recalled_on).less_than(options[:end_date]) if options[:end_date].present?

        # CDC/Food/Drug fields
        with(:food_type, options[:food_type]) unless options[:food_type].blank?

        # CPSC fields
        with(:upc, options[:upc]) unless options[:upc].blank?

        # NHTSA fields
        with(:make, options[:make]) unless options[:make].blank?
        with(:model, options[:model]) unless options[:model].blank?
        with(:year, options[:year]) unless options[:year].blank?
        with(:code, options[:code]) unless options[:code].blank?

        if options[:sort] == 'date'
          order_by :recalled_on, :desc
        end

        paginate page: page, per_page: per_page
      end
    end
  rescue RSolr::Error::Http => error
    Rails.logger.warn "Error in searching for Recalls: #{error.to_s}"
    nil
  end

  def cdc?
    organization == CDC
  end

  def cpsc?
    organization == CPSC
  end

  def nhtsa?
    organization == NHTSA
  end

  def highlighted_as_json(hit)
    result_hash = as_json
    return result_hash unless hit.highlights.present?

    case
    when cdc?
      CDC_HIGHLIGHTED_FIELDS.each do |cdc_field|
        field_name_sym = "food_recall_#{cdc_field}".to_sym
        highlighted_value = highlight_field(hit, field_name_sym)
        result_hash[cdc_field] = highlighted_value if highlighted_value
      end
    when cpsc?
      CPSC_HIGHLIGHTED_FIELDS.each do |field_name_sym|
        highlighted_value = highlight_field(hit, field_name_sym)
        hash_sym = "#{field_name_sym}s".to_sym
        result_hash[hash_sym] = [highlighted_value] if highlighted_value
      end
    when nhtsa?
      NHTSA_HIGHLIGHTED_FIELDS.each do |field_name_sym|
        highlighted_value = highlight_field(hit, field_name_sym)
        result_hash[field_name_sym] = highlighted_value if highlighted_value
      end
    end
    result_hash
  end

  def as_json(options = {})
    recall_hash = { organization: organization,
                    recall_number: recall_number,
                    recall_date: recalled_on ? recalled_on.to_s(:db) : nil,
                    recall_url: recall_url }

    detail_hash = case
                  when cdc? then cdc_hash
                  when cpsc? then cpsc_hash
                  when nhtsa? then nhtsa_hash
                  end
    recall_hash.merge!(detail_hash) if detail_hash
    recall_hash
  end

  def cdc_hash
    food_recall.as_json(only: [:summary, :description])
  end

  def cpsc_hash
    { manufacturers: recall_details_hash[:manufacturer],
      product_types: recall_details_hash[:product_type],
      descriptions: recall_details_hash[:description],
      upcs: recall_details_hash[:upc],
      hazards: recall_details_hash[:hazard],
      countries: recall_details_hash[:country] }
  end

  def nhtsa_hash
    hash = {
        records: auto_recalls.collect do |a|
          a.as_json(except: [:id, :recall_id, :created_at, :updated_at])
        end
    }

    NHTSA_DETAIL_FIELDS.each_key do |detail_type|
      key = detail_type.underscore.to_sym
      hash[key] = recall_details_hash[key].first if recall_details_hash[key]
    end
    hash
  end

  def recall_url
    case
    when cdc?
      food_recall.url
    when cpsc?
      "http://www.cpsc.gov/cpscpub/prerel/prhtml#{self.recall_number.to_s[0..1]}/#{self.recall_number}.html" unless self.recall_number.blank?
    when nhtsa?
      "http://www-odi.nhtsa.dot.gov/recalls/recallresults.cfm?start=1&SearchType=QuickSearch&rcl_ID=#{self.recall_number}&summary=true&PrintVersion=YES"
    end
  end

  def summary
    summary = case
              when cdc? then food_recall.summary
              when cpsc? then cpsc_summary
              when nhtsa? then nhtsa_summary
              end
    summary.blank? ? 'Click here to see products' : summary
  end

  def description
    case
    when cdc?
      food_recall.description
    when cpsc?
      product_types = recall_details_hash[:product_type] || []
      product_types.join(', ')
    when nhtsa?
      models = auto_recalls.collect do |ar|
        "#{ar.make} / #{ar.model}"
      end.uniq
      "#{'Recalls'.pluralize(models.count)} for: #{models.join(', ')}" if models.present?
    end
  end

  def recall_details_hash
    @recall_details_hash ||= begin
      recall_details_hash = {}
      recall_details.order(:id).each do |rd|
        key = rd.detail_type.underscore.to_sym
        if recall_details_hash[key]
          recall_details_hash[key] << rd.detail_value
        else
          recall_details_hash[key] = [rd.detail_value]
        end
      end
      recall_details_hash
    end
  end

  private

  def cpsc_summary
    recall_details_hash[:description].join(', ') if recall_details_hash[:description].present?
  end

  def nhtsa_summary
    component_description = recall_details_hash[:component_description]
    manufacturer = recall_details_hash[:manufacturer]
    if component_description.present? && manufacturer.present?
      "#{component_description.first} FROM #{manufacturer.first}"
    end
  end

  def highlight_field(hit, field_name)
    hit.highlight(field_name).format { |phrase| "\uE000#{phrase}\uE001" } if hit.highlight(field_name)
  end
end