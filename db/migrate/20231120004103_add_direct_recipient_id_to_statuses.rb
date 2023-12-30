class AddDirectRecipientIdToStatuses < ActiveRecord::Migration[7.0]
  def change
    add_column :statuses, :direct_recipient_id, :bigint, null: true
  end
end
