class AddUrlToStatuses < ActiveRecord::Migration[7.0]
  def change
    add_column :statuses, :url, :string, null: true, default: nil
  end
end
