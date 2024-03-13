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
end
