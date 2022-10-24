class CreateClientApps < ActiveRecord::Migration[7.0]
  def change
    create_table :client_apps do |t|
      t.string :url
      t.string :name
      t.string :logo_url

      t.timestamps
    end
  end
end
