require 'rails_helper'

RSpec.describe User, type: :model do
  describe "when creating a new registered user" do

    let(:indieweb_info) { {:authorization_endpoint => "#{ENV['INDIEAUTH_HOST']}/auth", :token_endpoint => "#{ENV['INDIEAUTH_HOST']}/token"} }

    before do
      allow(IndieWeb::Endpoints).to receive(:get).and_return(indieweb_info)
      @user = FactoryBot.create(:user)
    end

    it "should be valid" do
      expect(@user).to be_valid
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
  end
end
