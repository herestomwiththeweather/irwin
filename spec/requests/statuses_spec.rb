require 'rails_helper'

RSpec.describe "Statuses", type: :request do
  let(:server_url) { "https://#{ENV['SERVER_NAME']}" }
  let(:indieweb_info) { {:authorization_endpoint => "#{server_url}/auth", :token_endpoint => "#{server_url}/token"} }
  let(:webfinger_info) { {"subject"=>"acct:alice@example.com", "links"=>[{"rel"=>"self", "type"=>"application/activity+json", "href"=>"#{ENV['INDIEAUTH_HOST']}/actor/alice@example.com" }]} }
  let(:user) { create :user }
  let(:status) { create :status, account: user.account }
  let(:replies_url) { "#{server_url}/statuses/#{status.id}/replies" }

  describe "GET /statuses/1" do
    before do
      allow(IndieWeb::Endpoints).to receive(:get).and_return(indieweb_info)
      allow(WebFinger).to receive(:discover!).and_return(webfinger_info)
    end

    it 'returns success' do
      get status_url(status, format: :json)
      json = JSON.parse(response.body)

      expect(response.status).to eql(200)
      expect(response.media_type).to eql('application/activity+json')
      expect(json['type']).to eql('Note')
    end

    it 'returns camelcase keys' do
      get status_url(status, format: :json)
      json = JSON.parse(response.body)
      expect(json['attributedTo']).to eql("#{server_url}/actor/#{user.to_short_webfinger_s}")
    end

    it 'returns replies collection' do
      get status_url(status, format: :json)
      json = JSON.parse(response.body)
      expect(json['replies']['type']).to eql('Collection')
      expect(json['replies']['id']).to eql(replies_url)
      expect(json['replies']['first']['type']).to eql('CollectionPage')
      expect(json['replies']['first']['next']).to eql("#{replies_url}?page=1")
      expect(json['replies']['first']['partOf']).to eql(replies_url)
    end
  end

  describe "GET /statuses/1/replies" do
    before do
      allow(IndieWeb::Endpoints).to receive(:get).and_return(indieweb_info)
      allow(WebFinger).to receive(:discover!).and_return(webfinger_info)
    end

    it 'returns replies collection' do
      get replies_status_url(status, format: :json)
      json = JSON.parse(response.body)

      expect(response.status).to eql(200)
      expect(response.media_type).to eql('application/activity+json')
      expect(json['type']).to eql('Collection')
      expect(json['id']).to eql(replies_url)
      expect(json['first']['type']).to eql('CollectionPage')
      expect(json['first']['next']).to eql("#{replies_url}?page=1")
      expect(json['first']['partOf']).to eql(replies_url)
    end
  end

  describe "GET /statuses/1/replies?page=1" do
    before do
      allow(IndieWeb::Endpoints).to receive(:get).and_return(indieweb_info)
      allow(WebFinger).to receive(:discover!).and_return(webfinger_info)
    end

    it 'returns replies page' do
      get replies_status_url(status, format: :json), params: { page: 1 }
      json = JSON.parse(response.body)

      expect(response.status).to eql(200)
      expect(response.media_type).to eql('application/activity+json')
      expect(json['type']).to eql('CollectionPage')
      expect(json['partOf']).to eql(replies_url)
      expect(json['id']).to eql("#{replies_url}?page=1")
      expect(json['items']).to eql([])
    end
  end
end
