xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title @account.name
    xml.description "Public posts from #{@account.webfinger_to_s}"
    xml.link actor_url(id: @target_user.to_short_webfinger_s, host: ENV['SERVER_NAME'], protocol: 'https', format: request.format.symbol)

    @statuses.each do |status|
      xml.item do
        xml.title status.text.truncate(100)
        xml.description status.text
        xml.pubDate status.created_at.to_fs(:rfc822)
        xml.link status.uri.presence || status.local_uri
        xml.guid status.uri.presence || status.local_uri
      end
    end
  end
end
