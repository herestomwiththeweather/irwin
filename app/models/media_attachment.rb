class MediaAttachment < ApplicationRecord
  belongs_to :status
  belongs_to :account

  has_one_attached :file

  IMAGE_MIME_TYPES = %w(image/jpeg image/png image/gif image/heic image/heif image/webp image/avif).freeze
  VIDEO_MIME_TYPES = %w(video/webm video/mp4 video/quicktime video/ogg).freeze
  AUDIO_MIME_TYPES = %w(audio/wave audio/wav audio/x-wav audio/x-pn-wave audio/vnd.wave audio/ogg audio/vorbis audio/mpeg audio/mp3 audio/webm audio/flac audio/aac audio/m4a audio/x-m4a audio/mp4 audio/3gpp video/x-ms-asf).freeze

  def info
    {
      "width" => file.metadata['width'],
      "height" => file.metadata['height'],
      "type" => "Document",
      "url" => file.url,
      "mediaType" => content_type
    }.compact
  end

  def content_type
    return self[:content_type] if self[:content_type].present?
    file.attached? ? file.content_type : ''
  end

  def image?
    content_type.blank? || IMAGE_MIME_TYPES.include?(content_type)
  end

  def video?
    VIDEO_MIME_TYPES.include? content_type
  end

  def audio?
    AUDIO_MIME_TYPES.include? content_type
  end
end
