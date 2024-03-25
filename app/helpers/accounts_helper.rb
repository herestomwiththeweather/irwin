module AccountsHelper
  def name(account)
    account.name.blank? ? "(none)" : account.name
  end

  def follows_you(account)
    (current_user && account.follows?(current_user.account)) ? ' follows you' : ''
  end
end
