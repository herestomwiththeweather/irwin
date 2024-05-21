require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:server_url) { "https://#{ENV['SERVER_NAME']}" }
  let(:indieweb_info) { {:authorization_endpoint => "#{server_url}/auth", :token_endpoint => "#{server_url}/token"} }
  let(:webfinger_info) { {"subject"=>"acct:alice@example.com", "links"=>[{"rel"=>"self", "type"=>"application/activity+json", "href"=>"https://#{ENV['SERVER_NAME']}/actor/alice@example.com" }]} }
  let(:host) { ENV['SERVER_NAME'] }
  let(:user) { create :user }
  let(:actor_url) { "#{server_url}/actor/#{user.to_short_webfinger_s}" }
  let(:also_known_as_url) { "https://example.com/users/alice" }

  describe "GET /.well-known/webfinger" do
    before do
      allow(IndieWeb::Endpoints).to receive(:get).and_return(indieweb_info)
      allow(WebFinger).to receive(:discover!).and_return(webfinger_info)
    end

    it "returns success" do
      headers = { 'Accept' => 'application/jrd+json' }
      get "/.well-known/webfinger?resource=acct:#{user.username}@#{host}", headers: headers
      json = JSON.parse(response.body)

      expect(response).to have_http_status(200)
      expect(json['subject']).to eql(user.to_webfinger_s)
      expect(json['links'].select {|link| link['rel'] == 'self'}.first['href']).to eql(actor_url)
    end

    it "returns 400 for missing resource" do
      headers = { 'Accept' => 'application/jrd+json' }
      get "/.well-known/webfinger", headers: headers

      expect(response).to have_http_status(400)
    end
  end

  describe "GET /actor/alice@example.com" do
    before do
      allow(IndieWeb::Endpoints).to receive(:get).and_return(indieweb_info)
      allow(WebFinger).to receive(:discover!).and_return(webfinger_info)
    end

    it "returns success" do
      headers = {'Accept': 'application/json'}
      get actor_url, headers: headers
      json = JSON.parse(response.body)

      expect(response).to have_http_status(200)
    end

    it 'returns camelcase keys' do
      headers = {'Accept': 'application/json'}
      get actor_url, headers: headers
      json = JSON.parse(response.body)
      expect(json['preferredUsername']).to eql("alice")
    end

    it 'returns also_known_as' do
      account = user.account
      account.also_known_as = [ also_known_as_url ]
      account.save
      headers = {'Accept': 'application/json'}
      get actor_url, headers: headers
      json = JSON.parse(response.body)
      expect(json['alsoKnownAs'][0]).to eql(also_known_as_url)
    end

    it 'returns outbox' do
      headers = {'Accept': 'application/json'}
      get actor_url, headers: headers
      json = JSON.parse(response.body)
      expect(json['outbox']).to eql("#{actor_url}/outbox")
    end
  end

  describe "GET /actor/alice@example.com/outbox" do
    before do
      allow(IndieWeb::Endpoints).to receive(:get).and_return(indieweb_info)
      allow(WebFinger).to receive(:discover!).and_return(webfinger_info)
    end

    it "returns success" do
      headers = {'Accept': 'application/json'}
      get "#{actor_url}/outbox", headers: headers
      json = JSON.parse(response.body)

      expect(response).to have_http_status(200)
    end
  end
end
