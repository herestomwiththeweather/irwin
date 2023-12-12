class RepliesSerializer < ApplicationSerializer
  define_method('@context') do
    'https://www.w3.org/ns/activitystreams'
  end

  attr_accessor :action_name

  attributes :id, :type, '@context'
  attribute :first, if: -> { object.current_replies_page.nil? }
  attribute :part_of, if: -> { object.current_replies_page.present? }
  attribute :items, if: -> { object.current_replies_page.present? }

  def initialize(object, options={})
    super
    @action_name = options[:template]
  end

  def type
    object.current_replies_page.nil? ? "Collection" : "CollectionPage"
  end

  def id
    action_url_with_page(action_name, 'statuses', object.current_replies_page)
  end

  def first
    {
      type: 'CollectionPage',
      partOf: action_url_with_page(action_name, 'statuses'),
      next: action_url_with_page(action_name, 'statuses', 1)
    }
  end

  def part_of
    action_url_with_page(action_name, 'statuses')
  end

  def items
    object.replies.map(&:uri)
  end

  private

  def action_url_with_page(action, controller, page_number = nil)
    params = {action: action, controller: controller, id: object.id, protocol: 'https'}
    params[:page] = page_number if page_number
    url_for(params)
  end
end
