module AccountsHelper
  def name(account)
    account.name.blank? ? "(none)" : account.name
  end
end
