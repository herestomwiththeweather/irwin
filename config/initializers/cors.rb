Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"
    resource '/.well-known/webfinger/*', headers: :any, methods: [:get]
  end
end
