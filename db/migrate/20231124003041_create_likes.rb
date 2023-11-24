class CreateLikes < ActiveRecord::Migration[7.0]
  def change
    create_table :likes do |t|
      t.belongs_to :account, null: false, foreign_key: true
      t.belongs_to :status, null: false, foreign_key: true

      t.timestamps
    end
  end
end
