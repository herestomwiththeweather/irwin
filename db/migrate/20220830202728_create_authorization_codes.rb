class CreateAuthorizationCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :authorization_codes do |t|
      t.string :token
      t.string :client_id
      t.belongs_to :user, null: false, foreign_key: true
      t.string :redirect_uri
      t.datetime :expires_at
      t.string :scope

      t.timestamps
    end
    add_index :authorization_codes, :token, unique: true
  end
end
