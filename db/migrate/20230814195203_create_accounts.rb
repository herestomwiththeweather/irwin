class CreateAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :accounts do |t|
      t.text :public_key, default: ''
      t.string :identifier, default: ''
      t.string :preferred_username, default: ''
      t.string :name, default: ''

      t.string :following, default: ''
      t.string :followers, default: ''
      t.string :inbox, default: ''
      t.string :outbox, default: ''
      t.string :url, default: ''
      t.string :icon, default: ''

      t.text :summary, default: ''
      t.timestamps
    end
  end
end
