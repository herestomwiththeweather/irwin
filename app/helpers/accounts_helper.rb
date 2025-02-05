module AccountsHelper
  def name(account)
    account.name.blank? ? "(none)" : account.name
  end

  def first_url(account)
    account.bsky? ? JSON.parse(account.url)[0] : account.url
  end

  def follows_you(account)
    (current_user && account.follows?(current_user.account)) ? ' follows you' : ''
  end
end
