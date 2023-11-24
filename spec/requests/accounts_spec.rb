require 'rails_helper'

RSpec.describe "Accounts", type: :request do
  let(:indieweb_info) { {:authorization_endpoint => "#{ENV['INDIEAUTH_HOST']}/auth", :token_endpoint => "#{ENV['INDIEAUTH_HOST']}/token"} }
  let(:origin_url) { "https://example.com/users/actor" }
  let(:target_url) { "https://example.com/users/target" }
  let(:origin_account) { create :account, identifier: origin_url, name: "Origin" }
  let(:target_account) { create :account, identifier: target_url, name: "Target" }
  let(:keypair) { OpenSSL::PKey::RSA.new(2048) }
  let(:private_key) { keypair.to_pem }
  let(:recipient_user) { create :user }
  let(:recipient_url) { "#{ENV['INDIEAUTH_HOST']}/actor/#{recipient_user.to_short_webfinger_s}" }
  let(:follow) { create :follow, target_account: origin_account, account: recipient_user.account }
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

  before do
    allow(IndieWeb::Endpoints).to receive(:get).and_return(indieweb_info)

    # intended for recipient to fetch origin account
    allow(Account).to receive(:fetch_by_key).and_return(origin_account)
    origin_account.public_key = keypair.public_key.to_pem

    allow(Account).to receive(:fetch_and_create_or_update_mastodon_account).and_return(target_account)
    allow(Follow).to receive(:add).and_return(nil)
  end

  describe "like" do
    it "returns success" do
      receiver_inbox = "#{recipient_url}/inbox"

      activity = Activity.new(receiver_inbox, valid_like_attributes, origin_url, private_key)

      post receiver_inbox, params: valid_like_attributes.to_json, headers: activity.request_headers

      expect(response).to have_http_status(202)
    end
  end

  describe "move" do
    it "returns success" do
      allow(Follow).to receive(:find_by).and_return(follow)

      receiver_inbox = "#{recipient_url}/inbox"

      target_account.update(also_known_as: [origin_url])

      activity = Activity.new(receiver_inbox, valid_move_attributes, origin_url, private_key)

      post receiver_inbox, params: valid_move_attributes.to_json, headers: activity.request_headers

      expect(response).to have_http_status(202)
    end

    it "returns failure when activity object is different than origin url" do
      receiver_inbox = "#{recipient_url}/inbox"

      valid_move_attributes[:object] = 'https://example.com/users/victim'
      activity = Activity.new(receiver_inbox, valid_move_attributes, origin_url, private_key)

      post receiver_inbox, params: valid_move_attributes.to_json, headers: activity.request_headers

      expect(response).to have_http_status(401)
    end

    it "returns failure when origin is not followed" do
      receiver_inbox = "#{recipient_url}/inbox"

      target_account.update(also_known_as: [origin_url])

      activity = Activity.new(receiver_inbox, valid_move_attributes, origin_url, private_key)

      post receiver_inbox, params: valid_move_attributes.to_json, headers: activity.request_headers

      expect(response).to have_http_status(401)
    end
  end
end
