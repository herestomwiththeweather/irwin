class CreateAccessTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :access_tokens do |t|
      t.string :token
      t.belongs_to :authorization_code, null: false, foreign_key: true
      t.belongs_to :user, null: false, foreign_key: true
      t.datetime :expires_at

      t.timestamps
    end
    add_index :access_tokens, :token, unique: true
  end
end
