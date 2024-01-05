class AddUserIdToPreferences < ActiveRecord::Migration[7.0]
  def change
    add_column :preferences, :user_id, :bigint, null: true
  end
end
