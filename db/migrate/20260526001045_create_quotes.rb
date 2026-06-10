class CreateQuotes < ActiveRecord::Migration[7.1]
  def change
    create_table :quotes do |t|
      t.references :account, null: false, foreign_key: true
      t.references :status, null: false, foreign_key: true, index: { unique: true }
      t.string :approval_uri, index: { where: 'approval_uri IS NOT NULL' }
      t.references :quoted_account, null: true, foreign_key: { to_table: :accounts, on_delete: :nullify }
      t.references :quoted_status, null: true, foreign_key: { to_table: :statuses, on_delete: :nullify }
      t.integer :state, null: false, default: 0
      t.boolean :legacy, null: false, default: false

      t.timestamps
    end

    add_index :quotes, [:account_id, :quoted_account_id, :id]
    add_index :quotes, [:quoted_status_id, :id]
  end
end
