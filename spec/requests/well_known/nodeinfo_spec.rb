require 'rails_helper'

RSpec.describe "WellKnown::Nodeinfos", type: :request do
  let(:server_url) { "https://#{ENV['SERVER_NAME']}" }
  let(:indieweb_info) { {:authorization_endpoint => "#{server_url}/auth", :token_endpoint => "#{server_url}/token"} }

  describe "GET /nodeinfo/2.0" do
    before do
      allow(IndieWeb::Endpoints).to receive(:get).and_return(indieweb_info)
      create :preference
    end

    it 'returns openRegistrations' do
      headers = {'Accept': 'applications/json'}
      get nodeinfo_schema_url, headers: headers
      json = JSON.parse(response.body)
      expect(json['openRegistrations']).to eql(Preference.first.enable_registrations)
    end
  end
end
