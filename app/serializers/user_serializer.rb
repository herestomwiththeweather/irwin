class UserSerializer < ApplicationSerializer
  define_method('@context') do
    'https://www.w3.org/ns/activitystreams'
  end

  has_one :public_key, serializer: PublicKeySerializer

  attributes :id, :type, :preferred_username, :inbox, '@context', :following, :followers, :name, :summary, :url, :icon, :also_known_as

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
    object.account.icon
  end

  def also_known_as
    object.account.also_known_as
  end

  def action_url(action, controller)
    url_for(action: action, controller: controller, id: object.to_short_webfinger_s, protocol: 'https')
  end
end
