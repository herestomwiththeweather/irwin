class AddDomainToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :domain, :string, null: true
    add_index :accounts, [:preferred_username, :domain], unique: true
  end
end
