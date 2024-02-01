require 'net/https'

class HttpClient
  def initialize(request_url, actor_url, private_key, body = '')
    @url = URI(request_url)
    @actor_url = actor_url
    @private_key = private_key
    @body = body
  end

  def get
    @headers = request_headers('get')
    request(:get)
  end

  def post
    @headers = request_headers('post')
    request(:post)
  end

  def request_headers(method_string)
    if @body.present?
      headers = {"Content-type"=>"application/activity+json"}
      digest = "SHA-256=#{Digest::SHA256.base64digest(@body)}"
      headers['Digest'] = digest
    else
      headers = {'Accept': 'application/json'}
    end
    date = Time.now.utc.httpdate
    headers['Date'] = date

    signed_string = "(request-target): #{method_string} #{@url.path}\nhost: #{@url.host}\ndate: #{date}"
    signed_string += "\ndigest: #{digest}" if @body.present?
    keypair=OpenSSL::PKey::RSA.new(@private_key)
    signature = Base64.strict_encode64(keypair.sign(OpenSSL::Digest::SHA256.new, signed_string))
    digest_option = @body.present? ? ' digest' : ''
    headers['Signature'] = "keyId=\"#{@actor_url}\",signature=\"#{signature}\",headers=\"(request-target) host date#{digest_option}\""

    headers
  end

  private

  def request(method, redirects_left = 2)
    return nil if 0 == redirects_left

    request = build_request(method)
    http = Net::HTTP.new(@url.host, @url.port)
    http.use_ssl = true
    response = http.request(request)
    if response.is_a?(Net::HTTPRedirection)
      Rails.logger.info "#{self.class}#{__method__} #{response.code} redirect to: #{response['location']}"
      @url = URI(response['location'])
      return request(method, redirects_left - 1)
    elsif !response.is_a?(Net::HTTPSuccess)
      Rails.logger.info "#{self.class}#{__method__} error: #{response.code}: #{response.message}"
    end

    return {} if response.body.blank?

    content_type = response['Content-Type']

    if content_type.present? && content_type.include?('text/html')
      Rails.logger.info "#{self.class}#{__method__} error: received html from #{@url.host}"
      nil
    else
      JSON.parse(response.body)
    end

  rescue OpenSSL::SSL::SSLError => e
    Rails.logger.info "#{self.class}#{__method__} SSL error: #{e.message}"
    nil
  rescue Errno::ENETUNREACH => e
    Rails.logger.info "#{self.class}#{__method__} unreachable error: #{e.message}"
    nil
  rescue Errno::ECONNREFUSED => e
    Rails.logger.info "#{self.class}#{__method__} connection refused error: #{e.message}"
    nil
  rescue Errno::ECONNRESET => e
    Rails.logger.info "#{self.class}#{__method__} connection reset error: #{e.message}"
    nil
  rescue Net::ReadTimeout, Net::OpenTimeout => e
    Rails.logger.info "#{self.class}#{__method__} timeout error: #{e.message}"
    nil
  rescue JSON::ParserError
    Rails.logger.info "#{self.class}#{__method__} error: could not parse #{content_type || ''}: #{response.body}"
    nil
  rescue SocketError => e
    Rails.logger.info "#{self.class}#{__method__} socket error: #{e.message}"
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
