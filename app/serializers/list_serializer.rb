class ListSerializer < ApplicationSerializer
  define_method('@context') do
    'https://www.w3.org/ns/activitystreams'
  end

  attr_accessor :action_name

  attributes :id, :type, '@context', :total_items
  attribute :first, if: -> { object.current_page.nil? }
  attribute :part_of, if: -> { object.current_page.present? }
  attribute :ordered_items, if: -> { object.current_page.present? }
  attribute :previous, if: -> { previous_page? }
  attribute :next, if: -> { next_page? }

  ITEMS_PER_PAGE = 10

  def initialize(object, options={})
    super
    @action_name = options[:template]
  end

  def type
    object.current_page.nil? ? "OrderedCollection" : "OrderedCollectionPage"
  end

  def id
    action_url_with_page(action_name, 'users', object.current_page)
  end

  def first
    page_number = 1
    action_url_with_page(action_name, 'users', page_number)
  end

  def part_of
    action_url_with_page(action_name, 'users')
  end

  def ordered_items
    page_offset = object.current_page.to_i - 1
    object.account.send("account_#{action_name}").offset(ITEMS_PER_PAGE*page_offset).limit(ITEMS_PER_PAGE).map(&:identifier)
  end

  def previous
    action_url_with_page(action_name, 'users', object.current_page.to_i - 1)
  end

  def next
    action_url_with_page(action_name, 'users', object.current_page.to_i + 1)
  end

  def total_items
    object.account.send("account_#{action_name}").length
  end

  private

  def previous_page?
    object.current_page.present? && (object.current_page.to_i != 1)
  end

  def next_page?
    object.current_page.present? && (total_items > object.current_page.to_i * ITEMS_PER_PAGE)
  end

  def action_url_with_page(action, controller, page_number = nil)
    params = {action: action, controller: controller, id: object.to_short_webfinger_s, protocol: 'https'}
    params[:page] = page_number if page_number
    url_for(params)
  end
end
