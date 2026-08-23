class FediSignature
  ALGORITHM = 'rsa-sha256'

  def self.signing_string(header_names)
    header_names.map { |name| "#{name}: #{yield(name)}" }.join("\n")
  end

  def self.sign(signing_string, private_key)
    keypair = OpenSSL::PKey::RSA.new(private_key)
    Base64.strict_encode64(keypair.sign(OpenSSL::Digest::SHA256.new, signing_string))
  end

  def self.build_header(key_id, signature, header_names)
    "keyId=\"#{key_id}\",signature=\"#{signature}\",algorithm=\"#{ALGORITHM}\",headers=\"#{header_names.join(' ')}\""
  end

  def self.parse_header(signature_header)
    return nil if signature_header.blank?

    signature_hash = signature_header.split(',').map do |pair|
      pair.split('=', 2).map do |value|
        value.strip.gsub(/\A"/, '').gsub(/"\z/, '') # "foo" -> foo
      end
    end.to_h

    return nil if signature_hash['signature'].nil? || signature_hash['headers'].nil? || signature_hash['keyId'].nil?

    signature_hash
  end
end
