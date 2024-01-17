class CreateMediaAttachments < ActiveRecord::Migration[7.0]
  def change
    create_table :media_attachments do |t|
      t.string :remote_url, default: '', null: false
      t.belongs_to :status, null: false, foreign_key: true
      t.belongs_to :account, null: false, foreign_key: true

      t.timestamps
    end
  end
end
