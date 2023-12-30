class WebfingerSerializer < ActiveModel::Serializer
  attributes :subject, :links

  def subject
    object.to_webfinger_s
  end

  def links
    [
      {
        "rel": "self",
        "type": "application/activity+json",
        "href": "#{object.actor_url}"
      }
    ]
  end
end
