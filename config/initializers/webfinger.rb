WebFinger.http_config do |r|
  r.headers['User-Agent'] = "Ruby (Irwin/#{Irwin::Version.to_s}; +https://#{ENV['SERVER_NAME']}/)"
end
