class UserSerializer < ApplicationSerializer
  define_method('@context') do
    'https://www.w3.org/ns/activitystreams'
  end

  has_one :public_key, serializer: PublicKeySerializer

  attributes :id, :type, :preferred_username, :inbox, '@context'

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

  def action_url(action, controller)
    url_for(action: action, controller: controller, id: object.to_short_webfinger_s, protocol: 'https')
  end
end
