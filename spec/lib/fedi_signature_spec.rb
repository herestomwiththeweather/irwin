require 'rails_helper'

RSpec.describe FediSignature do
  let(:keypair) { OpenSSL::PKey::RSA.new(2048) }
  let(:private_key) { keypair.to_pem }
  let(:public_key) { keypair.public_key.to_pem }
  let(:key_id) { "https://example.com/users/actor#main-key" }
  let(:headers) { "(request-target) host date" }
  let(:date) { "Sun, 23 Aug 2026 17:09:09 GMT" }

  describe ".parse_header" do
    it "extracts keyId, headers, signature" do
      signature_header = "keyId=\"#{key_id}\",algorithm=\"rsa-sha256\",headers=\"#{headers}\",signature=\"abc123\""

      signature_hash = FediSignature.parse_header(signature_header)

      expect(signature_hash['keyId']).to eq(key_id)
      expect(signature_hash['headers']).to eq(headers)
      expect(signature_hash['signature']).to eq('abc123')
    end

    it "returns nil when keyId is missing" do
      signature_header = 'algorithm="rsa-sha256",headers="#{headers}",signature="abc123"'
      expect(FediSignature.parse_header(signature_header)).to be_nil
    end

    it "returns nil when headers is missing" do
      signature_header = "keyId=\"#{key_id}\",algorithm=\"rsa-sha256\",signature=\"abc123\""
      expect(FediSignature.parse_header(signature_header)).to be_nil
    end

    it "returns nil when signature is missing" do
      signature_header = "keyId=\"#{key_id}\",algorithm=\"rsa-sha256\",headers=\"#{headers}\""
      expect(FediSignature.parse_header(signature_header)).to be_nil
    end

    it "returns nil for a blank header" do
      expect(FediSignature.parse_header(nil)).to be_nil
      expect(FediSignature.parse_header('')).to be_nil
    end
  end

  describe ".signing_string" do
    it "joins header names and values with newlines" do
      header_values = { 'host' => 'example.com', 'date' => date }
      signing_string = FediSignature.signing_string(['host', 'date']) { |name| header_values[name] }
      expect(signing_string).to eq("host: example.com\ndate: #{date}")
    end
  end

  describe ".build_header" do
    it "builds the Signature header" do
      header_names = ['(request-target)', 'host', 'date']
      header = FediSignature.build_header(key_id, 'abc123', header_names)
      expect(header).to eq('keyId="https://example.com/users/actor#main-key",signature="abc123",algorithm="rsa-sha256",headers="(request-target) host date"')
    end
  end
end
