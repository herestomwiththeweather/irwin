require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Irwin
  module Version
    module_function

    def major
      0
    end

    def minor
      0
    end

    def patch
      1
    end

    def to_a
      [major, minor, patch]
    end

    def prerelease
      ENV.fetch('IRWIN_VERSION_PRERELEASE', 'alpha.1')
    end

    def to_s
      "#{to_a.join('.')}-#{prerelease}"
    end
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.time_zone = ENV['INDIEAUTH_TIME_ZONE'] || 'UTC'

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.active_job.queue_adapter = :sidekiq
    if ENV['EXCEPTION_NOTIFICATION']
      config.middleware.use ExceptionNotification::Rack,
        email: {
          sender_address: %("Application Error" <app.error@#{ENV['SMTP_DOMAIN']}>),
          exception_recipients: ENV['EXCEPTION_NOTIFICATION'].split,
          email_prefix: "[Irwin] "
        }
    end
  end
end
