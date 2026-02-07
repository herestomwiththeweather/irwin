class CreateNetworkEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :network_events do |t|
      t.references :host, null: false, foreign_key: true
      t.integer :event_type
      t.text :message
      t.string :path
      t.text :backtrace

      t.timestamps
    end
  end
end
