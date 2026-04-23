class WebfingerSerializer < ApplicationSerializer
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
      },
      {
        "rel": "https://w3id.org/fep/3b86/Follow",
        "template": "https://#{default_url_options[:host]}/authorize_interaction?uri={object}"
      },
      { "rel": "https://w3id.org/fep/3b86/Like",
        "template": "https://#{default_url_options[:host]}/intents/like?objectId={object}"
      }
    ]
  end
end
