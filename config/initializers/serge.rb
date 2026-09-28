Rails.application.config.to_prepare do
  Serge::InboxDelivery.logger = Rails.logger
end
