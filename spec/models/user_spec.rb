require 'rails_helper'

RSpec.describe User, type: :model do
  describe "when creating a new registered user" do

    let(:indieweb_info) { {:authorization_endpoint => "https://#{ENV['SERVER_NAME']}/auth", :token_endpoint => "https://#{ENV['SERVER_NAME']}/token"} }
    let(:webfinger_info) { {"subject" => "acct:alice@example.com", "links"=>[{"rel"=>"self", "type"=>"application/activity+json", "href"=>"https://#{ENV['SERVER_NAME']}/actor/alice@example.com" }]} }
    let(:webfinger_info_bob) { {"subject"=>"acct:bob@example.com", "links"=>[{"rel"=>"self", "type"=>"application/activity+json", "href"=>"https://#{ENV['SERVER_NAME']}/actor/bob@example.com" }]} }

    before do
      allow(IndieWeb::Endpoints).to receive(:get).and_return(indieweb_info)
      allow(WebFinger).to receive(:discover!).with('acct:alice@example.com').and_return(webfinger_info)
      allow(WebFinger).to receive(:discover!).with('acct:bob@example.com').and_return(webfinger_info_bob)
      account = Account.create(preferred_username: 'alice', domain: 'example.com', url: 'https://example.com', identifier: 'https://example.com')
      @user = FactoryBot.create(:user, account: account)
      @user_without_account = FactoryBot.create(:user, url: 'https://example2.com')
    end

    it "should be valid" do
      expect(@user).to be_valid
    end

    it "should be valid without an account" do
      expect(@user_without_account).to be_valid
    end

    it "should have a valid short webfinger name" do
      expect(@user.to_short_webfinger_s =~ /^(?!\@)/).to be_truthy
    end

    it "should have an actor_url that matches url from user serializer" do
      serializer = UserSerializer.new(@user)
      serialization = ActiveModelSerializers::Adapter.create(serializer)
      expected_value = JSON.parse(serialization.to_json)['id']
      expect(@user.actor_url).to eq(expected_value)
    end

    it "should have a unique url" do
      expect { FactoryBot.create(:user, url: 'https://example.com') }.to raise_error(ActiveRecord::RecordInvalid).with_message('Validation failed: Url has already been taken')
    end

    it "should have a unique account preferred_username" do
      new_account = Account.create(preferred_username: 'alice', domain: 'test.com', url: 'https://test.com', identifier: 'https://test.com')
      expect { FactoryBot.create(:user, url: 'https://test.com', account: new_account) }.to raise_error(ActiveRecord::RecordInvalid).with_message('Validation failed: Account another user has an account with that preferred_username')
    end
  end
end
