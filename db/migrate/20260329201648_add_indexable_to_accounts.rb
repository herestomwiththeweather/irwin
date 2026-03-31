class AddIndexableToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :indexable, :boolean, default: false, null: false
  end
end
