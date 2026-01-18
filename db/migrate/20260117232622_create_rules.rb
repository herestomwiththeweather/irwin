class CreateRules < ActiveRecord::Migration[7.1]
  def change
    create_table :rules do |t|
      t.text :text, null: false, default: ''
      t.integer :priority, null: false, default: 0

      t.timestamps
    end
  end
end
