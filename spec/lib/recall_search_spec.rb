require 'spec_helper'

describe RecallSearch do
  describe '.recent' do
    context 'when options include page' do
      it 'should not override page' do
        RecallSearch.should_receive(:new).with(sort: 'date', page: 3, per_page: 10)
        RecallSearch.recent(page: 3)
      end
    end

    context 'when options include page' do
      it 'should not override per_page' do
        RecallSearch.should_receive(:new).with(sort: 'date', page: 1, per_page: 5)
        RecallSearch.recent(per_page: 5)
      end
    end
  end
end