ActiveSupport::Notifications.subscribe 'http_client.network_events' do |name, start, finish, id, payload|
  host = Host.find_or_create_by(name: payload[:host])
  NetworkEvent.create!(
    host: host,
    event_type: NetworkEvent.event_type_for(payload[:name]),
    message: payload[:message],
    path: payload[:path],
    backtrace: payload[:backtrace]
  )
end

