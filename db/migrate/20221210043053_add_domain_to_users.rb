class AddDomainToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :domain, :string, default: '', null: false
  end
end
