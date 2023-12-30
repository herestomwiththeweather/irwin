class CreatePreferences < ActiveRecord::Migration[7.0]
  def change
    create_table :preferences do |t|
      t.boolean :enable_registrations, default: true

      t.timestamps
    end
  end
end
