class RecallSearch
  def initialize(options = {})
    @options = options
    @search = Recall.search_for(@options) ||
        Struct.new(:total, :results).new(0, [])
  end

  def as_json(options = {})
    { success: { total: @search.total,
                 results: results_as_json } }
  end

  def results
    @search.results
  end

  def self.recent(options = {})
    RecallSearch.new(options.merge(sort: 'date').reverse_merge(page: 1, per_page: 10))
  end

  private

  def results_as_json
    @options[:hl] == '1' ? highlighted_results_as_json : @search.results.collect { |r| r.as_json }
  end

  def highlighted_results_as_json
    json_results = []
    @search.each_hit_with_result do |hit, result|
      json_results << result.highlighted_as_json(hit)
    end
    json_results
  end
end