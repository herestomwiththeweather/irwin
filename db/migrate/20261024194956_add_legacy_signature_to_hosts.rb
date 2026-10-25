class AddLegacySignatureToHosts < ActiveRecord::Migration[7.1]
  def change
    add_column :hosts, :legacy_signature, :boolean, default: false, null: false
  end
end
