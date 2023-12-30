class AddMovedToAccountIdToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :moved_to_account_id, :bigint, null: true
  end
end
