class AddGuestToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :guest, :boolean, default: true
  end
end
