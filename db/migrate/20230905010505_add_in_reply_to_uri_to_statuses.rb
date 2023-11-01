class AddInReplyToUriToStatuses < ActiveRecord::Migration[7.0]
  def change
    add_column :statuses, :in_reply_to_uri, :string, null: true, default: nil
  end
end
