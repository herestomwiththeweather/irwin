class ClientApp < ApplicationRecord
  has_many :authorization_codes
  validates :url, presence: true, uniqueness: true

  class << self
    def fetch(client_url)
      client = find_or_create_by(url: client_url)
      doc = Microformats.parse client_url
      h_app = doc['items'].select {|i| i['type'].include?('h-app')}
      props = h_app.first['properties']
      client.name = props['name'].first
      client.logo_url = props['logo'].first
      client.save
      client
    rescue => e
      Rails.logger.info "ClientApp#fetch Error: #{e.message}"
      client
    end
  end
end
