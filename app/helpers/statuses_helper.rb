module StatusesHelper
  REMOVED = 'bg-red-100 text-red-600 font-bold'
  ADDED = 'bg-green-100 text-green-600 font-bold'

  def sanitized(status, view_context)
    sanitize status.local? ? StatusPresenter.new(status, view_context).marked_up_text : status.text_with_modified_mentions, tags: %w(b i u p a span blockquote br), attributes: %w(href data-turbo data-turbo-frame translate class)
  end

  def diff_text(old, new)
    old_words = old.split
    new_words = new.split

    diffs = Diff::LCS.sdiff(old_words, new_words)

    diffs.map do |change|
      case change.action
      when '='
        ERB::Util.html_escape(change.old_element)
      when '!'
        "<span class='#{REMOVED}'>#{ERB::Util.html_escape(change.old_element)}</span> " \
        "<span class='#{ADDED}'>#{ERB::Util.html_escape(change.new_element)}</span>"
      when '+'
        "<span class='#{ADDED}'>#{ERB::Util.html_escape(change.new_element)}</span>"
      when '-'
        "<span class='#{REMOVED}'>#{ERB::Util.html_escape(change.old_element)}</span>"
      end
    end.join(' ').html_safe
  end

  def new_status_submit_text(status, direct_recipient_id)
    prefix = direct_recipient_id.present? ? 'DM ' : ''
    "#{prefix}#{status.present? ? 'Reply' : 'Post'}"
  end

  def reply_to_and_mentions(status)
    mentions = status.mentions_found
    mentions << status.account.webfinger_to_s
    mentions.uniq!
    mentions.map {|m| "@#{m}"}.join(" ")
  end

  def local_or_origin_link(status)
    link_text = "#{time_ago_in_words(status.created_at)} ago"

    if "statuses" == controller_name && "show" == action_name && status.uri.present?
      link_to(link_text, status.uri, target: '_blank')
    else
      link_to(link_text, status_path(status), data: {'turbo-frame': '_top'} )
    end
  end

  def classes_for_type(status)
    classes = ''
    classes << ' border-2 border-blue-700' if status.reblog.present?
    classes << ' bg-slate-100' if status.private_mention?
    classes
  end
end
