require 'net/https'

class HttpClient
  def initialize(url, headers = {'Accept': 'application/json'}, body = '')
    @url = URI(url)
    @headers = headers
    @body = body
  end

  def get
    request(:get)
  end

  def post
    request(:post)
  end

  private

  def request(method)
    request = build_request(method)
    http = Net::HTTP.new(@url.host, @url.port)
    http.use_ssl = true
    response = http.request(request)
    if response.is_a?(Net::HTTPSuccess)
      response.body.blank? ? {} : JSON.parse(response.body)
    else
      Rails.logger.info "#{self.class}#{__method__} error: #{response.code}: #{response.message}"
      nil
    end
  rescue OpenSSL::SSL::SSLError => e
    Rails.logger.info "#{self.class}#{__method__} SSL error: #{e.message}"
    return nil
  rescue JSON::ParserError
    Rails.logger.info "#{self.class}#{__method__} error: could not parse response: #{response.body}"
    nil
  end

  def build_request(method)
    request = case method
    when :get
      Net::HTTP::Get.new(@url, @headers)
    when :post
      Net::HTTP::Post.new(@url, @headers)
    end

    request.body = @body if [:post].include?(method)
    request
  end
end
