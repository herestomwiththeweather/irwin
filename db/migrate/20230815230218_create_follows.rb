class CreateFollows < ActiveRecord::Migration[7.0]
  def change
    create_table :follows do |t|
      t.bigint :account_id, null: false
      t.bigint :target_account_id, null: false
      t.string :identifier
      t.string :uri
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :follows, [:account_id, :target_account_id], unique: true
    add_index :follows, :identifier
  end
end
