class CreateMentions < ActiveRecord::Migration[7.0]
  def change
    create_table :mentions do |t|
      t.integer :account_id
      t.integer :status_id
      t.boolean :silent

      t.timestamps
    end

    add_index :mentions, [:account_id, :status_id], unique: true
    add_index :mentions, :status_id
  end
end
