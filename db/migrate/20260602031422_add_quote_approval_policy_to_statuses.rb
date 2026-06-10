class AddQuoteApprovalPolicyToStatuses < ActiveRecord::Migration[7.1]
  def change
    add_column :statuses, :quote_approval_policy, :integer, null: false, default: 0
  end
end
