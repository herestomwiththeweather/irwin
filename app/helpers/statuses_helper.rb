module StatusesHelper
  def new_status_submit_text(status, direct_recipient_id)
    prefix = direct_recipient_id.present? ? 'DM ' : ''
    "#{prefix}#{status.present? ? 'Reply' : 'Post'}"
  end
end
