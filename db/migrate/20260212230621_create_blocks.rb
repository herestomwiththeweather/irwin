class CreateBlocks < ActiveRecord::Migration[7.1]
  def change
    create_table :blocks do |t|
      t.belongs_to :account, null: false, foreign_key: true
      t.bigint :target_account_id
      t.string :uri
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
