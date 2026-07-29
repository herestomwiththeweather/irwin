class Rack::Attack
  Rack::Attack.blocklist('deny from blocklist') do |req|
    IpBlock.blocked?(req.env['action_dispatch.remote_ip'].to_s)
  end
end
