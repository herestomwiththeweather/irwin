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

  def get(legacy_signature = false)
    @headers = request_headers('get', legacy_signature)
    request(:get)
  end

  def post(legacy_signature = false)
    @headers = request_headers('post', legacy_signature)
    request(:post)
  end

  def request_headers(method_string, legacy_signature = false)
    if !legacy_signature && Host.find_by(name: @url.host)&.legacy_signature
      Rails.logger.info "#{self.class}##{__method__} setting legacy signature for #{@url.host}"
      legacy_signature = true
    end

    if @body.present?
      headers = {"Content-type"=>"application/activity+json"}
    else
      headers = {'Accept': 'application/activity+json, application/json, application/ld+json'}
    end
    date = Time.now.utc.httpdate
    headers['Date'] = date
    headers['User-Agent'] = "Ruby (Irwin/#{Irwin::Version.to_s}; +https://#{ENV['SERVER_NAME']}/)"

    if legacy_signature
      Rails.logger.info "#{self.class}##{__method__} signing request with cavage"
      header_names = ['(request-target)', 'host', 'date']
      if @body.present?
        header_names << 'digest'
        digest = "SHA-256=#{Digest::SHA256.base64digest(@body)}"
        headers['Digest'] = digest
      end

      header_values = {
        '(request-target)' => "#{method_string} #{@url.path}",
        'host' => @url.host,
        'date' => date,
        'digest' => digest,
      }

      signing_string = Serge::FediSignature.signing_string(header_names) { |name| header_values[name] }
      signature = Serge::FediSignature.sign(signing_string, @private_key)

      headers['Signature'] = Serge::FediSignature.build_header(@main_key_url, signature, header_names)
    else
      Rails.logger.info "#{self.class}##{__method__} signing request with rfc9421"

      headers.merge!(
        Serge::MessageSignature.headers(
          method: method_string,
          url: @url,
          body: @body,
          public_key_id: @main_key_url,
          private_key: @private_key
        )
      )
    end

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
      Rails.logger.info "#{self.class}##{__method__} #{response.code} redirect to: #{response['location']}"
      redirect_url = URI(response['location'])
      @url = redirect_url.scheme.present? ? redirect_url : @url.merge(redirect_url)
      return request(method, redirects_left - 1)
    elsif !response.is_a?(Net::HTTPSuccess)
      if response.is_a?(Net::HTTPUnauthorized) && @headers.key?('Signature-Input')
        Rails.logger.info "#{self.class}##{__method__} retrying #{@url.host} with cavage signature: #{response.code}: #{response.message}"
        @headers = request_headers(method.to_s, true)
        return request(method, redirects_left)
      else
        Rails.logger.info "#{self.class}##{__method__} error from #{@url.host}: #{response.code}: #{response.message}"
        return nil
      end
    end

    return {} if response.body.blank?

    content_type = response['Content-Type']

    if content_type.present? && content_type.include?('text/html')
      Rails.logger.info "#{self.class}##{__method__} error from #{@url.host}: received html"
      # treat html response to post as success. see https://github.com/herestomwiththeweather/irwin/issues/37.
      method == :post ? { html_response: response.body } : nil
    else
      JSON.parse(response.body).presence || {}
    end

  rescue OpenSSL::SSL::SSLError,
         Errno::ENETUNREACH,
         Errno::ECONNREFUSED,
         Errno::ECONNRESET,
         Net::ReadTimeout,
         Net::OpenTimeout,
         JSON::ParserError,
         SocketError,
         EOFError => e

    ActiveSupport::Notifications.instrument('http_client.network_events', name: e.class.name, message: e.message, host: @url.host, path: @url.path, backtrace: e.backtrace&.join("\n"))
    error_type = case e
                 when OpenSSL::SSL::SSLError then 'SSL error'
                 when Errno::ENETUNREACH then 'unreachable error'
                 when Errno::ECONNREFUSED then 'connection refused error'
                 when Errno::ECONNRESET then 'connection reset error'
                 when Net::ReadTimeout, Net::OpenTimeout then 'timeout error'
                 when JSON::ParserError then 'JSON parse error'
                 when SocketError then 'socket error'
                 when EOFError then 'EOF error'
                 end
    detail = case e
             when JSON::ParserError then "could not parse #{content_type || ''}: #{response.body}"
             else e.message
             end
    Rails.logger.info "#{self.class}#{__method__} #{error_type} from #{@url.host}: #{detail}"
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
