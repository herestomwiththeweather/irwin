json.extract! network_event, :id, :host_id, :event_type, :message, :path, :backtrace, :created_at, :updated_at
json.url network_event_url(network_event, format: :json)
