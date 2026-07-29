class CreateIpBlocks < ActiveRecord::Migration[7.1]
  def change
    create_table :ip_blocks do |t|
      t.inet :ip, null: false, default: '0.0.0.0'
      t.timestamps
    end
  end
end
