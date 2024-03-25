require 'rails_helper'

RSpec.describe Status, type: :model do

  let(:account) { create :account }
  let(:alice_url) { "https://example.com/users/alice" }
  let(:bob_url) { "https://example.com/users/bob" }
  let(:alice_account) { create :account, domain: 'example.com', preferred_username: 'alice', identifier: alice_url, name: "Alice" }
  let(:bob_account) { create :account, domain: 'example.com', preferred_username: 'bob', identifier: bob_url, name: "Bob" }
  let(:content) { 'having coffee with alice@example.com and @bob@example.com at Cafe Caffeine' }
  let(:remote_content) { "<p>mention test: <span class=\"h-card\" translate=\"no\"><a href=\"https://example.com/@alice\" class=\"u-url mention\">@<span>alice@example.com</span></a></span> hello</p>" }

  describe "When creating a status" do
    before do
      other_status = create :status, account_id: account.id, text: 'other status', uri: 'https://example.com/1'
    end

    it 'should not allow the same uri to be used by two statuses' do
      status = Status.create(account_id: account.id, text: 'test', uri: 'https://example.com/1')
      expect(status.errors[:uri]).to include('has already been taken')
    end

    it 'should create a mention for each webfinger address in the body' do
      allow(account).to receive(:local?).and_return(true)
      # reference alice and bob so that they can be queried before calling fetch_and_create_mastodon_account_by_address
      mentioned_accounts = [alice_account, bob_account]
      status = Status.create(account: account, text: content, uri: 'https://example.com/2')
      expect(status.mentions.length).to eq(2)
    end

    it 'should find an anchor tag in the status text of a remote status for each mention' do
      status = Status.create(account: bob_account, text: remote_content, uri: 'https://example.com/3')
      status.mentions << Mention.new(account: bob_account, silent: false)
      expect(status.mention_anchors_found.length).to eq(1)
    end
  end
end
