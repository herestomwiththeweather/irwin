require 'rails_helper'

RSpec.describe "Accounts", type: :request do
  let(:server_url) { "https://#{ENV['SERVER_NAME']}" }
  let(:indieweb_info) { {:authorization_endpoint => "#{server_url}/auth", :token_endpoint => "#{server_url}/token"} }
  let(:webfinger_info) { {"subject"=>"acct:alice@example.com", "links"=>[{"rel"=>"self", "type"=>"application/activity+json", "href"=>"https://#{ENV['SERVER_NAME']}/actor/alice@example.com" }]} }
  let(:origin_url) { "https://example.com/users/actor" }
  let(:target_url) { "https://example.com/users/target" }
  let(:origin_account) { create :account, identifier: origin_url, name: "Origin" }
  let(:target_account) { create :account, identifier: target_url, name: "Target" }
  let(:keypair) { OpenSSL::PKey::RSA.new(2048) }
  let(:private_key) { keypair.to_pem }
  let(:alice_account) { create :account, preferred_username: 'alice', domain: 'example.com' }
  let(:recipient_user) { create :user, account_id: alice_account.id }
  let(:recipient_url) { "#{server_url}/actor/#{recipient_user.to_short_webfinger_s}" }
  let(:follow) { create :follow, target_account: origin_account, account: alice_account }
  let(:target_status) { create :status, account_id: recipient_user.account.id, uri: nil }
  let(:valid_move_attributes) do
    { id: 'https://example.com/users/actor#moves/123',
      type: 'Move',
      target: target_url,
      actor: origin_url,
      object: origin_url
    }
  end
  let(:valid_like_attributes) do
    { id: 'https://example.com/users/actor#likes/123',
      type: 'Like',
      actor: origin_url,
      object: target_status.local_uri
    }
  end

  let(:valid_undo_attributes) do
    { id: 'https://example.com/users/actor#likes/123',
      type: 'Undo',
      actor: origin_url,
      object: {
        id: target_status.local_uri,
        type: "Like",
        actor: origin_url,
        object: target_status.local_uri
      }
    }
  end

  let(:remote_status) { create :status, account_id: origin_account.id, uri: "#{origin_url}/statuses/123" }
  let(:valid_delete_attributes) do
    { id: "#{origin_url}#deletes/123",
      type: 'Delete',
      actor: origin_url,
      object: remote_status.uri
    }
  end

  before do
    allow(IndieWeb::Endpoints).to receive(:get).and_return(indieweb_info)
    allow(WebFinger).to receive(:discover!).and_return(webfinger_info)

    # intended for recipient to fetch origin account
    allow(Account).to receive(:fetch_by_key).and_return(origin_account)
    origin_account.public_key = keypair.public_key.to_pem

    allow(Account).to receive(:fetch_and_create_or_update_mastodon_account).and_return(target_account)
    allow(Follow).to receive(:add).and_return(nil)
  end

  describe "like" do
    it "returns success for both creating a like and then undoing it" do
      receiver_inbox = "#{recipient_url}/inbox"

      activity = Activity.new(receiver_inbox, valid_like_attributes.to_json, origin_url, private_key)

      post receiver_inbox, params: valid_like_attributes.to_json, headers: activity.request_headers

      expect(response).to have_http_status(202)

      undo_activity = Activity.new(receiver_inbox, valid_undo_attributes.to_json, origin_url, private_key)

      post receiver_inbox, params: valid_undo_attributes.to_json, headers: undo_activity.request_headers

      expect(response).to have_http_status(202)
    end
  end

  describe "move" do
    it "returns success" do
      allow(Follow).to receive(:find_by).and_return(follow)

      receiver_inbox = "#{recipient_url}/inbox"

      target_account.update(also_known_as: [origin_url])

      activity = Activity.new(receiver_inbox, valid_move_attributes.to_json, origin_url, private_key)

      post receiver_inbox, params: valid_move_attributes.to_json, headers: activity.request_headers

      expect(response).to have_http_status(202)
    end

    it "returns failure when activity object is different than origin url" do
      receiver_inbox = "#{recipient_url}/inbox"

      valid_move_attributes[:object] = 'https://example.com/users/victim'
      activity = Activity.new(receiver_inbox, valid_move_attributes.to_json, origin_url, private_key)

      post receiver_inbox, params: valid_move_attributes.to_json, headers: activity.request_headers

      expect(response).to have_http_status(401)
    end

    it "returns failure when origin is not followed" do
      receiver_inbox = "#{recipient_url}/inbox"

      target_account.update(also_known_as: [origin_url])

      activity = Activity.new(receiver_inbox, valid_move_attributes.to_json, origin_url, private_key)

      post receiver_inbox, params: valid_move_attributes.to_json, headers: activity.request_headers

      expect(response).to have_http_status(401)
    end
  end

  describe "delete" do
    it "returns success and deletes the status when actor owns it" do
      receiver_inbox = "#{recipient_url}/inbox"

      activity = Activity.new(receiver_inbox, valid_delete_attributes.to_json, origin_url, private_key)

      post receiver_inbox, params: valid_delete_attributes.to_json, headers: activity.request_headers

      expect(response).to have_http_status(202)
      expect(Status.find_by(id: remote_status.id)).to be_discarded
    end

    it "returns failure when actor does not own the status" do
      other_account = create :account, identifier: "https://other.example/user", name: "Other"
      remote_status.update(account_id: other_account.id)

      receiver_inbox = "#{recipient_url}/inbox"

      activity = Activity.new(receiver_inbox, valid_delete_attributes.to_json, origin_url, private_key)

      post receiver_inbox, params: valid_delete_attributes.to_json, headers: activity.request_headers

      expect(response).to have_http_status(401)
    end
  end
end
