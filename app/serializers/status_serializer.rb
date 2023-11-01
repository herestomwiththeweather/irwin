class StatusSerializer < ApplicationSerializer

  attributes :id, :type, :in_reply_to, :published, :content, :attributed_to, :language, :to, :cc

  def id
    action_url('show', 'statuses')
  end

  def type
    'Note'
  end

  def in_reply_to
    object.thread.present? ? object.thread.uri : nil 
  end
  
  def published
    object.created_at.iso8601
  end

  def content
    object.text
  end

  def attributed_to 
    object.account.user.actor_url
  end

  def language
    object.language
  end

  def to
    [
      "https://www.w3.org/ns/activitystreams#Public"
    ]
  end

  def cc
    cc_list = [
      object.account.user.followers_url
    ]

    if object.thread.present?
      cc_list << object.thread.account.identifier
    end

    cc_list
  end

  def action_url(action, controller)
    url_for(action: action, controller: controller, id: object.id, protocol: 'https')
  end
end
