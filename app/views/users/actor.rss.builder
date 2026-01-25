xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title @account.name
    xml.description "Public posts from #{@account.webfinger_to_s}"
    xml.link actor_url(id: @target_user.to_short_webfinger_s, host: ENV['SERVER_NAME'], protocol: 'https', format: request.format.symbol)

    @statuses.each do |status|
      xml.item do
        xml.title status.text.truncate(100)

        description_html = ActionController::Base.helpers.auto_link(status.text, html: { target: '_blank', rel: 'nofollow noopener noreferrer' }, link: :urls)
        status.media_attachments.select(&:image?).each do |media|
          url = media.remote_url.presence || (media.file.attached? ? media.file.url : nil)
          if url
            alt = media.description.present? ? " alt=\"#{media.description}\"" : ""
            description_html += "<br/><img src=\"#{url}\"#{alt}/>".html_safe
          end
        end
        xml.description description_html

        xml.pubDate status.created_at.to_fs(:rfc822)
        xml.link status.uri.presence || status.local_uri
        xml.guid status.uri.presence || status.local_uri

        status.media_attachments.select { |m| m.audio? || m.video? }.each do |media|
          url = media.remote_url.presence || (media.file.attached? ? media.file.url : nil)
          if url
            xml.enclosure url: url, type: media.content_type
          end
        end
      end
    end
  end
end
