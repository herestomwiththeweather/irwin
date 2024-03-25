class StatusSerializer < ApplicationSerializer
  define_method('@context') do
    'https://www.w3.org/ns/activitystreams'
  end

  attr_accessor :action_name

  attributes :id, :type, '@context', :in_reply_to, :published, :content_map, :content, :attributed_to, :language, :to, :cc, :replies
  attribute :tag, unless: -> { object.mentions.empty? }
  attribute :attachment, unless: -> { object.media_attachments.empty? }

  def initialize(object, options={})
    super
    @action_name = options[:template]
  end

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

  def content_map
    {
      language => marked_up_text
    }
  end

  def content
    marked_up_text
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

  def tag
    object.mentions.map {|mention| {"type": "Mention", "href": mention.account.identifier, "name": "@#{mention.account.webfinger_to_s}"}}
  end

  def attachment
    object.media_attachments.map {|media_attachment| media_attachment.info}
  end

  def replies
    {
      id: object.replies_uri,
      type: 'Collection',
      first: {
        type: 'CollectionPage',
        partOf: object.replies_uri,
        next: object.replies_first_page_uri,
        items: []
      }
    }
  end

  def marked_up_text
    @marked_up_text ||= StatusPresenter.new(object, @instance_options[:view_context]).marked_up_text
  end

  def action_url(action, controller)
    url_for(action: action, controller: controller, id: object.id, protocol: 'https')
  end
end
