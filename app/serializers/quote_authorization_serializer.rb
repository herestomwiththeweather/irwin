class QuoteAuthorizationSerializer < ApplicationSerializer
  define_method('@context') do
    [
      'https://www.w3.org/ns/activitystreams',
      {
        'QuoteAuthorization' => 'https://w3id.org/fep/044f#QuoteAuthorization',
        'gts' => 'https://gotosocial.org/ns#',
        'interactingObject' => {
          '@id' => 'gts:interactingObject',
          '@type' => '@id'
        },
        'interactionTarget' => {
          '@id' => 'gts:interactionTarget',
          '@type' => '@id'
        }
      }
    ]
  end

  attributes :id, :type, '@context', :attributed_to, :interacting_object, :interaction_target

  def id
    action_url('show', 'quote_authorizations')
  end

  def type
    'QuoteAuthorization'
  end

  def attributed_to 
    object.quoted_account.identifier
  end

  def interacting_object
    object.status.uri
  end

  def interaction_target
    object.quoted_status.uri
  end

  private

  def action_url(action, controller)
    url_for(action: action, controller: controller, id: object.id, protocol: 'https')
  end
end
