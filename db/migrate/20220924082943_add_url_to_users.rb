class AddUrlToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :url, :string, default: ''
  end
end
