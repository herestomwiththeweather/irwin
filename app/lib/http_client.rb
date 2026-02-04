require 'net/https'

class HttpClient
  def initialize(request_url, main_key_url, private_key, body = '')
    @main_key_url = main_key_url
    @private_key = private_key
    @body = body
    @url = URI(request_url)
  rescue URI::InvalidURIError => e
    Rails.logger.info "#{self.class}##{__method__} invalid uri error: #{e.message}"
    @url = URI(URI::Parser.new.escape(unescape_unicode(request_url)))
  end

  def self.urls_equal?(url1, url2)
    uri1 = URI.parse(url1).normalize
    uri2 = URI.parse(url2).normalize
    uri1.path = uri1.path.chomp('/') if uri1.path
    uri2.path = uri2.path.chomp('/') if uri2.path
    uri1 == uri2
  rescue URI::InvalidURIError
    false
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
      headers = {'Accept': 'application/activity+json, application/json, application/ld+json'}
    end
    date = Time.now.utc.httpdate
    headers['Date'] = date
    headers['User-Agent'] = "Ruby (Irwin/#{Irwin::Version.to_s}; +https://#{ENV['SERVER_NAME']}/)"

    signed_string = "(request-target): #{method_string} #{@url.path}\nhost: #{@url.host}\ndate: #{date}"
    signed_string += "\ndigest: #{digest}" if @body.present?
    keypair=OpenSSL::PKey::RSA.new(@private_key)
    signature = Base64.strict_encode64(keypair.sign(OpenSSL::Digest::SHA256.new, signed_string))
    digest_option = @body.present? ? ' digest' : ''
    headers['Signature'] = "keyId=\"#{@main_key_url}\",signature=\"#{signature}\",algorithm=\"rsa-sha256\",headers=\"(request-target) host date#{digest_option}\""

    headers
  end

  private

  def unescape_unicode(request_url)
    # https://stackoverflow.com/questions/7015778/is-this-the-best-way-to-unescape-unicode-escape-sequences-in-ruby
    #
    request_url.gsub(/\\u([\da-fA-F]{4})/) { [$1].pack("H*").unpack("n*").pack("U*") }
  end

  def request(method, redirects_left = 2)
    return nil if 0 == redirects_left

    request = build_request(method)
    http = Net::HTTP.new(@url.host, @url.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 10
    response = http.request(request)
    if response.is_a?(Net::HTTPRedirection)
      Rails.logger.info "#{self.class}#{__method__} #{response.code} redirect to: #{response['location']}"
      redirect_url = URI(response['location'])
      @url = redirect_url.scheme.present? ? redirect_url : @url.merge(redirect_url)
      return request(method, redirects_left - 1)
    elsif !response.is_a?(Net::HTTPSuccess)
      Rails.logger.info "#{self.class}#{__method__} error from #{@url.host}: #{response.code}: #{response.message}"
    end

    return {} if response.body.blank?

    content_type = response['Content-Type']

    if content_type.present? && content_type.include?('text/html')
      Rails.logger.info "#{self.class}#{__method__} error from #{@url.host}: received html"
      { html_response: response.body }
    else
      JSON.parse(response.body).presence || {}
    end

  rescue OpenSSL::SSL::SSLError => e
    Rails.logger.info "#{self.class}#{__method__} SSL error from #{@url.host}: #{e.message}"
    nil
  rescue Errno::ENETUNREACH => e
    Rails.logger.info "#{self.class}#{__method__} unreachable error from #{@url.host}: #{e.message}"
    nil
  rescue Errno::ECONNREFUSED => e
    Rails.logger.info "#{self.class}#{__method__} connection refused error from #{@url.host}: #{e.message}"
    nil
  rescue Errno::ECONNRESET => e
    Rails.logger.info "#{self.class}#{__method__} connection reset error from #{@url.host}: #{e.message}"
    nil
  rescue Net::ReadTimeout, Net::OpenTimeout => e
    Rails.logger.info "#{self.class}#{__method__} timeout error from #{@url.host}: #{e.message}"
    nil
  rescue JSON::ParserError
    Rails.logger.info "#{self.class}#{__method__} error from #{@url.host}: could not parse #{content_type || ''}: #{response.body}"
    nil
  rescue SocketError => e
    Rails.logger.info "#{self.class}#{__method__} socket error from #{@url.host}: #{e.message}"
    nil
  rescue EOFError => e
    Rails.logger.info "#{self.class}#{__method__} EOF error from #{@url.host}: #{e.message}"
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
