require 'rails_helper'

RSpec.describe Account, type: :model do
  describe "when creating a new account" do
    before do
      @account = FactoryBot.create(:account)
    end

    it "should be valid" do
      expect(@account).to be_valid
    end
  end

  describe "when creating a new account via webfinger" do
    let(:bob_webfinger_info) { {"subject" => "acct:bob@example.com", "links"=>[{"rel"=>"self", "type"=>"application/activity+json", "href"=>"https://activitypub.test/users/bob" }]} }
    let(:bob_actor_info) { {"id"=>"https://activitypub.test/users/bob",
 "preferredUsername"=>"bob",
 "name"=>"Bob",
 "@context"=>"https://www.w3.org/ns/activitystreams",
 "publicKey"=>
    {"id"=>"https://activitypub.test/users/bob#main-key",
     "owner"=>"https://activitypub.test/users/bob",
   "publicKeyPem"=>
    "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtMjXEZo79cWems45DNJ/\nFnrzhkRmvHEpqdBRwdsNzwqXNMQYPn3Gsy5S1ZlfdmRlCE8aW/SFcjPgYq3nK0zZ\nVKL+ci8AuWIgRflfCQOYC1HzKwmaGc7ojK94AtrvVgfVYNc0YXo0MVk3uv6qZxXY\nHRF5l8UMgdGkcZvvylSAX7i86gLm64vVTS7/3mzM8FHDm6+omtX6oX0jaBbA4PdP\nqMHtg9AqP5ZiF7IT1oiVxygoeP21HnzoBXc+ndjgonNQYKz7HvOwW6EzLliG+MPV\n1O8lPC22/h1+jgeBUmgmA4oSJHehfrmrXq4xXl+xCX+GI2U7dOeJcqSbTi3gNLoD\nVQIDAQAB\n-----END PUBLIC KEY-----\n"}} }

    before do
      allow(WebFinger).to receive(:discover!).with('acct:bob@example.com').and_return(bob_webfinger_info)
      allow(WebFinger).to receive(:discover!).with('acct:bob@activitypub.test').and_return(bob_webfinger_info)
      allow(Account).to receive(:fetch_mastodon_account).with('https://activitypub.test/users/bob').and_return(bob_actor_info)
    end

    it "should use the custom domain" do
      account = Account.fetch_and_create_mastodon_account_by_address('bob@example.com')
      expect(account.domain).to eq('example.com')
    end
  end
end
