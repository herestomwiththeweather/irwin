require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:indieweb_info) { {:authorization_endpoint => "#{ENV['INDIEAUTH_HOST']}/auth", :token_endpoint => "#{ENV['INDIEAUTH_HOST']}/token"} }
  let(:host) { ENV['INDIEAUTH_HOST'].sub('https://','') }
  let(:user) { create :user }

  describe "GET /.well-known/webfinger" do
    before do
      allow(IndieWeb::Endpoints).to receive(:get).and_return(indieweb_info)
    end

    it "returns success" do
      headers = { 'Accept' => 'application/jrd+json' }
      get "/.well-known/webfinger?resource=#{user.username}@#{host}", headers: headers
      json = JSON.parse(response.body)

      expect(response).to have_http_status(200)
      expect(json['subject']).to eql(user.to_webfinger_s)
      expect(json['links'].select {|link| link['rel'] == 'self'}.first['href']).to eql("#{ENV['INDIEAUTH_HOST']}/actor/#{user.to_short_webfinger_s}")
    end
  end

  describe "GET /actor/alice@example.com" do
    before do
      allow(IndieWeb::Endpoints).to receive(:get).and_return(indieweb_info)
    end

    it "returns success" do
      headers = {'Accept': 'application/json'}
      get "#{ENV['INDIEAUTH_HOST']}/actor/#{user.to_short_webfinger_s}", headers: headers
      puts "2"
      puts response.body
      json = JSON.parse(response.body)

      expect(response).to have_http_status(200)
    end

    it 'returns camelcase keys' do
      headers = {'Accept': 'application/json'}
      get "#{ENV['INDIEAUTH_HOST']}/actor/#{user.to_short_webfinger_s}", headers: headers
      puts "3"
      puts response.body
      json = JSON.parse(response.body)
      expect(json['preferredUsername']).to eql("alice")
    end
  end
end
