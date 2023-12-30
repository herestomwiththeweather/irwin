class ApplicationSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  default_url_options[:host] = ENV['INDIEAUTH_HOST'].sub('https://','')
end
