require 'rails_helper'

RSpec.describe "Statuses", type: :request do
  let(:indieweb_info) { {:authorization_endpoint => "#{ENV['INDIEAUTH_HOST']}/auth", :token_endpoint => "#{ENV['INDIEAUTH_HOST']}/token"} }
  let(:user) { create :user }
  let(:status) { create :status, account: user.account }

  describe "GET /statuses/1" do
    before do
      allow(IndieWeb::Endpoints).to receive(:get).and_return(indieweb_info)
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
      expect(json['attributedTo']).to eql("#{ENV['INDIEAUTH_HOST']}/actor/#{user.to_short_webfinger_s}")
    end
  end
end
