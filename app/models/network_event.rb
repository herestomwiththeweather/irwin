class NetworkEvent < ApplicationRecord
  belongs_to :host

  enum :event_type, {
    ssl_error: 0,
    unreachable: 1,
    connection_refused: 2,
    connection_reset: 3,
    read_timeout: 4,
    open_timeout: 5,
    json_parse_error: 6,
    socket_error: 7,
    eof_error: 8
  }

  CLASS_NAME_TO_EVENT_TYPE = {
    'OpenSSL::SSL::SSLError' => :ssl_error,
    'Errno::ENETUNREACH' => :unreachable,
    'Errno::ECONNREFUSED' => :connection_refused,
    'Errno::ECONNRESET' => :connection_reset,
    'Net::ReadTimeout' => :read_timeout,
    'Net::OpenTimeout' => :open_timeout,
    'JSON::ParserError' => :json_parse_error,
    'SocketError' => :socket_error,
    'EOFError' => :eof_error
  }.freeze

  def self.event_type_for(class_name)
    CLASS_NAME_TO_EVENT_TYPE[class_name]
  end
end
