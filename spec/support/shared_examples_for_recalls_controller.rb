shared_examples 'recalls controller' do |methods|
  methods.each do |method|
    context "when get #{method} request contains an invalid page parameter" do
      before do
        Recall.should_not_receive(:recent)
        get "#{method}", format: :json, page: '1000'
      end

      it { should respond_with(:bad_request) }
    end

    context "when get #{method} request contains an invalid per_page parameter" do
      before do
        Recall.should_not_receive(:recent)
        get "#{method}", format: :json, per_page: '1000'
      end

      it { should respond_with(:bad_request) }
    end
  end
end