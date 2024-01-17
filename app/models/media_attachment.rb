class MediaAttachment < ApplicationRecord
  belongs_to :status
  belongs_to :account

  has_one_attached :file

  def info
    {
      "width" => file.metadata['width'],
      "height" => file.metadata['height'],
      "type" => "Document",
      "url" => file.url,
      "mediaType" => "image/jpeg"
    }.compact
  end
end
