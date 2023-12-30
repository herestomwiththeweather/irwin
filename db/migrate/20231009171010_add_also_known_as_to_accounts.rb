class AddAlsoKnownAsToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :also_known_as, :string, array: true
  end
end
