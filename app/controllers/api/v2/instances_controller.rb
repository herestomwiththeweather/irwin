module Api
  module V2
    class InstancesController < ApplicationController
      skip_before_action :verify_authenticity_token

      def show
        rules = Rule.order(:priority, :id).map do |rule|
          {
            id: rule.id.to_s,
            text: rule.text,
            hint: "",
            translations: {}
          }
        end

        render json: {
          domain: ENV['SERVER_NAME'],
          title: ENV['SERVER_NAME'],
          version: Irwin::Version.to_s,
          source_url: 'https://github.com/herestomwiththeweather/irwin',
          description: "Users are known on the social web using their own domain rather than this server's domain.",
          languages: ['en'],
          rules: rules
        }
      end
    end
  end
end
