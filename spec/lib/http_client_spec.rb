require 'rails_helper'

RSpec.describe HttpClient do
  let(:actor_url) { "https://example.com/users/actor" }
  let(:keypair) { OpenSSL::PKey::RSA.new(2048) }
  let(:private_key) { keypair.to_pem }
  let(:uri_with_unicode) { "https://i18n.viii.fi/@\\u4F60\\u597D" }
  let(:uri_with_unicode_unescaped) { "https://i18n.viii.fi/@\u4F60\u597D" }
  describe "when instantiating a new http client" do
    it "should accept unicode" do
      puts uri_with_unicode_unescaped
      client = HttpClient.new(uri_with_unicode, actor_url, private_key)
      expect(client).to be_instance_of(HttpClient)
    end
  end
end 
