class AddReblogOfIdToStatuses < ActiveRecord::Migration[7.0]
  def change
    add_column :statuses, :reblog_of_id, :bigint
  end
end
