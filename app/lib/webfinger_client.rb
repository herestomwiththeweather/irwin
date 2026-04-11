class WebfingerClient
  def initialize(address)
    @address = address&.strip&.delete_prefix('@')
    @username, @domain = @address.split('@')
    @json_response = nil
  end

  def acct_uri
    "acct:#{@address}"
  end

  def discover
    @json_response = WebFinger.discover! acct_uri
  rescue WebFinger::Exception, NoMethodError => e
    case e
    when WebFinger::NotFound
      Rails.logger.info "#{__method__} Error: WebFinger unexpectedly not found for #{@address}: #{e.message}"
    when WebFinger::BadRequest
      # see https://github.com/swicg/activitypub-webfinger/issues/28
      Rails.logger.info "#{__method__} Error: Bad request for webfinger: #{@address}: #{e.message}"
    when WebFinger::Unauthorized
      Rails.logger.info "#{__method__} Error: Unauthorized webfinger request for #{@address}: #{e.message}"
    when WebFinger::Forbidden
      Rails.logger.info "#{__method__} Error: Forbidden webfinger request for #{@address}: #{e.message}"
    when NoMethodError
      Rails.logger.info "#{__method__} Error: Bad webfinger response: #{@address}: #{e.message}"
    else
      # e.g. "Failed to open TCP connection"
      Rails.logger.info "#{__method__} Error: WebFinger exception for #{@address}: #{e.message}"
    end
    nil
  end

  def actor_url
    discover if @json_response.nil?
    return nil if @json_response.nil?
    @json_response['links'].select {|link| link['rel'] == 'self'}.first['href']
  end

  def username
    @username
  end

  def domain
    @domain
  end
end
