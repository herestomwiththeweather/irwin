class AddIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :users, :account_id
    add_index :statuses, :reblog_of_id
  end
end
