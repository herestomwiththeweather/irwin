class AdminConstraint
  def matches?(request)
    if request.session[:user_id].present?
      user = User.find_by(id: request.session[:user_id])
      user.present? && !user.guest?
    else
      false
    end
  end
end
