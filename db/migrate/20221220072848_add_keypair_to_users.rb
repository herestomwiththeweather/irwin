class AddKeypairToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :public_key, :text, null: false, default: ''
    add_column :users, :private_key, :text
  end
end
