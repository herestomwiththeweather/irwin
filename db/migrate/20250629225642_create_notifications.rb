class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :account, foreign_key: true
      t.belongs_to :status, foreign_key: true
      t.datetime :read_at
      t.string :message
      t.string :type

      t.timestamps
    end
  end
end
