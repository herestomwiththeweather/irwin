unless Rails.env.test?
  ActionMailer::Base.delivery_method = :smtp
  smtp_port = ENV['SMTP_PORT'] ? ENV['SMTP_PORT'].to_i : 587
  starttls_auto = 587==smtp_port ? true : false
  ActionMailer::Base.smtp_settings = {
    :address        => ENV['SMTP_SERVER'] || 'smtp.sendgrid.net',
    :port           => smtp_port,
    :authentication => :plain,
    :enable_starttls_auto => starttls_auto,
    :user_name      => ENV['SMTP_USER'],
    :password       => ENV['SMTP_PASSWORD'],
    :domain         => ENV['SMTP_DOMAIN'] || 'herokuapp.com'
  }
  ActionMailer::Base.default_url_options[:host] = ENV['SERVER_NAME']
  ActionMailer::Base.default_url_options[:protocol] = 'https'
end
