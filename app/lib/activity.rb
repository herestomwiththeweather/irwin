class Activity
  def initialize(inbox_url, body, actor_url, private_key)
    @inbox_url = inbox_url
    @body = body
    @actor_url = actor_url
    @private_key = private_key
  end

  def request_headers
    url = URI.parse(@inbox_url)
    headers = {"Content-type"=>"application/activity+json"}
    digest = "SHA-256=#{Digest::SHA256.base64digest(@body.to_json)}"
    headers['Digest'] = digest
    date = Time.now.utc.httpdate
    headers['Date'] = date

    signed_string = "(request-target): post #{url.path}\nhost: #{url.host}\ndate: #{date}\ndigest: #{digest}"
    keypair=OpenSSL::PKey::RSA.new(@private_key)
    signature = Base64.strict_encode64(keypair.sign(OpenSSL::Digest::SHA256.new, signed_string))
    headers['Signature'] = "keyId=\"#{@actor_url}\",signature=\"#{signature}\",headers=\"(request-target) host date digest\""

    headers
  end
end
