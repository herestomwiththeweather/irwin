module StatusesHelper
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
