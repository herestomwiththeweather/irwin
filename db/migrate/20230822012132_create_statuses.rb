class CreateStatuses < ActiveRecord::Migration[7.0]
  def change
    create_table :statuses do |t|
      t.string :language
      t.string :uri
      t.integer :visibility, default: 0, null: false
      t.text :text, default: "", null: false
      t.belongs_to :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
