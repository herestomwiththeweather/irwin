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

  describe "when creating a new local account" do
    let(:misconfigured_actor_url) { "https://activitypub.test/user/bob" }
    let(:bob_webfinger_info) { {"subject" => "acct:bob@example.com", "links"=>[{"rel"=>"self", "type"=>"application/activity+json", "href"=>"#{misconfigured_actor_url}" }]} }
    let(:indieweb_info) { {:authorization_endpoint => "https://#{ENV['SERVER_NAME']}/auth", :token_endpoint => "https://#{ENV['SERVER_NAME']}/token"} }

    before do
      allow(IndieWeb::Endpoints).to receive(:get).and_return(indieweb_info)
      allow(WebFinger).to receive(:discover!).with('acct:bob@example.com').and_return(bob_webfinger_info)
      @user_without_account = FactoryBot.create(:user, url: 'https://example.com')
    end

    it "should be invalid if the actor url returned by webfinger is different than the expected actor url" do
      account = Account.new(preferred_username: 'bob', domain: 'example.com')
      account.user = @user_without_account
      account.save
      expect(account.errors[:base]).to include("Webfinger: Expected #{account.user.actor_url} but found #{misconfigured_actor_url}")
    end
  end

  describe "when creating a new account via webfinger" do
    let(:bob_webfinger_info) { {"subject" => "acct:bob@example.com", "links"=>[{"rel"=>"self", "type"=>"application/activity+json", "href"=>"https://activitypub.test/users/bob" }]} }
    let(:empty_webfinger_info) { {"subject" => "acct:empty@example.com", "links"=>[{"rel"=>"self", "type"=>"application/activity+json", "href"=>"https://activitypub.test/users/empty" }]} }
    let(:evil_webfinger_info) { {"subject" => "acct:victim@victim.test", "links"=>[{"rel"=>"self", "type"=>"application/activity+json", "href"=>"https://activitypub.test/users/evil" }]} }
    let(:victim_webfinger_info) { {"subject" => "acct:victim@victim.test", "links"=>[{"rel"=>"self", "type"=>"application/activity+json", "href"=>"https://victim.test/users/victim" }]} }

    let(:bob_actor_info) { {"id"=>"https://activitypub.test/users/bob",
 "preferredUsername"=>"bob",
 "name"=>"Bob",
 "@context"=>"https://www.w3.org/ns/activitystreams",
 "publicKey"=>
    {"id"=>"https://activitypub.test/users/bob#main-key",
     "owner"=>"https://activitypub.test/users/bob",
   "publicKeyPem"=>
    "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtMjXEZo79cWems45DNJ/\nFnrzhkRmvHEpqdBRwdsNzwqXNMQYPn3Gsy5S1ZlfdmRlCE8aW/SFcjPgYq3nK0zZ\nVKL+ci8AuWIgRflfCQOYC1HzKwmaGc7ojK94AtrvVgfVYNc0YXo0MVk3uv6qZxXY\nHRF5l8UMgdGkcZvvylSAX7i86gLm64vVTS7/3mzM8FHDm6+omtX6oX0jaBbA4PdP\nqMHtg9AqP5ZiF7IT1oiVxygoeP21HnzoBXc+ndjgonNQYKz7HvOwW6EzLliG+MPV\n1O8lPC22/h1+jgeBUmgmA4oSJHehfrmrXq4xXl+xCX+GI2U7dOeJcqSbTi3gNLoD\nVQIDAQAB\n-----END PUBLIC KEY-----\n"}} }

    let(:evil_actor_info) { {"id"=>"https://victim.test/users/victim",
 "preferredUsername"=>"victim",
 "name"=>"Victim",
 "@context"=>"https://www.w3.org/ns/activitystreams",
 "publicKey"=>
    {"id"=>"https://victim.test/users/victim#main-key",
     "owner"=>"https://victim.test/users/victim",
   "publicKeyPem"=>
    "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtMjXEZo79cWems45DNJ/\nFnrzhkRmvHEpqdBRwdsNzwqXNMQYPn3Gsy5S1ZlfdmRlCE8aW/SFcjPgYq3nK0zZ\nVKL+ci8AuWIgRflfCQOYC1HzKwmaGc7ojK94AtrvVgfVYNc0YXo0MVk3uv6qZxXY\nHRF5l8UMgdGkcZvvylSAX7i86gLm64vVTS7/3mzM8FHDm6+omtX6oX0jaBbA4PdP\nqMHtg9AqP5ZiF7IT1oiVxygoeP21HnzoBXc+ndjgonNQYKz7HvOwW6EzLliG+MPV\n1O8lPC22/h1+jgeBUmgmA4oSJHehfrmrXq4xXl+xCX+GI2U7dOeJcqSbTi3gNLoD\nVQIDAQAB\n-----END PUBLIC KEY-----\n"}} }

    before do
      # forward discovery addresses
      allow(WebFinger).to receive(:discover!).with('acct:bob@example.com').and_return(bob_webfinger_info)
      allow(WebFinger).to receive(:discover!).with('acct:empty@example.com').and_return(empty_webfinger_info)
      allow(WebFinger).to receive(:discover!).with('acct:evil@example.com').and_return(evil_webfinger_info)
      # reverse discovery addresses
      allow(WebFinger).to receive(:discover!).with('acct:bob@activitypub.test').and_return(bob_webfinger_info)
      allow(WebFinger).to receive(:discover!).with('acct:victim@victim.test').and_return(victim_webfinger_info)

      allow(Account).to receive(:fetch_actor).with('https://activitypub.test/users/bob').and_return(bob_actor_info)
      allow(Account).to receive(:fetch_actor).with('https://activitypub.test/users/empty').and_return(nil)
      allow(Account).to receive(:fetch_actor).with('https://activitypub.test/users/evil').and_return(evil_actor_info)
    end

    it "should use the custom domain" do
      account = Account.fetch_and_create_mastodon_account_by_address('bob@example.com')
      expect(account.domain).to eq('example.com')
    end

    it "should not create an account if fetching actor url fails" do
      account = Account.fetch_and_create_mastodon_account_by_address('empty@example.com')
      expect(account).to eq(nil)
    end

    it "should reject an actor document whose id does not match the requested url" do
      account = Account.fetch_and_create_mastodon_account_by_address('evil@example.com')
      expect(account).to eq(nil)
    end
  end
end
