require 'rails_helper'

RSpec.describe Status, type: :model do

  let(:account) { create :account }

  describe "When creating a status" do
    before do
      other_status = create :status, account_id: account.id, text: 'other status', uri: 'https://example.com/1'
    end

    it 'should not allow the same uri to be used by two statuses' do
      status = Status.create(account_id: account.id, text: 'test', uri: 'https://example.com/1')
      expect(status.errors[:uri]).to include('has already been taken')
    end
  end
end
