require 'rails_helper'

RSpec.describe Follow, type: :model do
  let(:account) { create :account }
  let(:target_account) { create :account }
  let(:uri1) { 'https://example.com/activity/1234' }
  let(:uri2) { 'https://example.com/activity/5678' }

  context 'follow' do
    before do
      @follow = FactoryBot.create(:follow, account: account, target_account: target_account, uri: uri1)
    end

    it "should be valid" do
      expect(@follow).to be_valid
    end

    it "should update uri of original follow if it receives redundant follow" do
      @follow2 = Follow.add(account, target_account, uri2)
      expect(@follow2.uri).to eq(uri2)
      expect(@follow2.identifier).to eq(@follow.identifier)
    end
  end
end
