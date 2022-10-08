class AddPkceChallengeToAuthorizationCodes < ActiveRecord::Migration[7.0]
  def change
    add_column :authorization_codes, :pkce_challenge, :string, default: ''
  end
end
