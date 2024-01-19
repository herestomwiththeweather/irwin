class AddDescriptionAndContentTypeToMediaAttachments < ActiveRecord::Migration[7.0]
  def change
    add_column :media_attachments, :description, :text, default: ''
    add_column :media_attachments, :content_type, :string, default: ''
  end
end
