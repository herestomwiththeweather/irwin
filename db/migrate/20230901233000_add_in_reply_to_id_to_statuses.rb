class AddInReplyToIdToStatuses < ActiveRecord::Migration[7.0]
  def change
    add_column :statuses, :in_reply_to_id, :bigint, null: true
    add_index :statuses, :in_reply_to_id
  end
end
