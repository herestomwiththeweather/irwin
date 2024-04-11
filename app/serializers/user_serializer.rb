class UserSerializer < ApplicationSerializer
  define_method('@context') do
    'https://www.w3.org/ns/activitystreams'
  end

  has_one :public_key, serializer: PublicKeySerializer

  attributes :id, :type, :preferred_username, :inbox, :outbox, '@context', :following, :followers, :name, :summary, :url, :also_known_as, :attachment
  attribute :icon, if: -> { object.account.icon.present? }
  attribute :image, if: -> { object.account.image.present? }

  def type
    "Person"
  end

  def preferred_username
    object.username
  end

  def public_key
    object
  end

  def id
    action_url('actor', 'users')
  end

  def inbox
    action_url('inbox', 'accounts')
  end

  def outbox
    action_url('outbox', 'accounts')
  end

  def following
    action_url('following', 'users')
  end

  def followers
    action_url('followers', 'users')
  end

  def name
    object.account.name
  end

  def summary
    object.account.summary
  end

  def url
    object.account.url
  end

  def icon
    { "type"=>"Image", "mediaType"=>"image/jpeg", "url"=> object.account.icon }
  end

  def image
    { "type"=>"Image", "mediaType"=>"image/jpeg", "url"=> object.account.image }
  end

  def also_known_as
    object.account.also_known_as
  end

  def attachment
    [
      {
        "type"=>"PropertyValue",
        "name"=>"my website",
        "value" => "<a href=\"#{object.url}\" target=\"_blank\" rel=\"nofollow noopener noreferrer me\" translate=\"no\"><span class=\"invisible\">https://</span><span class=\"\">#{object.domain}</span><span class=\"invisible\"></span></a>"
      }
    ]
  end

  def action_url(action, controller)
    url_for(action: action, controller: controller, id: object.to_short_webfinger_s, protocol: 'https')
  end
end
