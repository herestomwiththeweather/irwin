class PublicKeySerializer < ApplicationSerializer
  attributes :id, :owner, :public_key_pem

  def id
    url_for(action: 'actor', controller: 'users', id: object.to_short_webfinger_s, protocol: 'https', anchor: 'main-key')
  end

  def owner
    url_for(action: 'actor', controller: 'users', id: object.to_short_webfinger_s, protocol: 'https')
  end

  def public_key_pem
    object.public_key
  end
end
