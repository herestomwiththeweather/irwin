class StatusPresenter < SimpleDelegator
  include ERB::Util

  def initialize(model, view)
    @model, @view = model, view
    super(@model)
  end

  def logged_in?
    @view && @view.current_user
  end

  def mention_url(mention)
    logged_in? ? @view.social_account_path(mention.account.webfinger_to_s) : mention.account.url
  end

  def turbo_data
    logged_in? ? {'turbo': 'false'} : {}
  end

  def text_with_linked_urls_and_mentions
    output = ActionController::Base.helpers.auto_link(@model.text, html: { translate: 'no', target: '_blank', rel: 'nofollow noopener noreferrer' }, link: :urls)
    @model.mentions.each do |mention|
      mention_link = "<span class=\"h-card\">#{ActionController::Base.helpers.link_to("@#{h(mention.account&.preferred_username)}", mention_url(mention), data: turbo_data)}</span>"
      output.gsub!( /@#{mention.account.webfinger_to_s}/i, mention_link)
    end

    output
  end

  def marked_up_text
    "<p>#{text_with_linked_urls_and_mentions}</p>"
  end
end
