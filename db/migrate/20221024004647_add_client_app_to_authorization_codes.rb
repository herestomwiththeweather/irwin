class AddClientAppToAuthorizationCodes < ActiveRecord::Migration[7.0]
  def change
    add_column :authorization_codes, :client_app_id, :bigint
  end
end
