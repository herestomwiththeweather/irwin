module StatusesHelper
  def new_status_submit_text(status)
    status.present? ? 'Reply' : 'Post'
  end
end
