class RemoveRegisteredFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :registered, :boolean
  end
end
