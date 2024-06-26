class Activity
  def initialize(inbox_url, body, key_url, private_key)
    @inbox_url = inbox_url
    @body = body
    @key_url = key_url
    @private_key = private_key
  end

  def request_headers
    client = HttpClient.new(@inbox_url, @key_url, @private_key, @body)
    client.request_headers('post')
  end
end
