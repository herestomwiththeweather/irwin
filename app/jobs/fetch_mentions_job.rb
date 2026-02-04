class FetchMentionsJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 2

  def perform(status_id, mentions_data)
    status = Status.find(status_id)

    mentions_data.each do |tag|
      next unless tag['type'] == 'Mention'

      Rails.logger.info "#{self.class}##{__method__} found mention: #{tag['name']} : #{tag['href']}"
      account = Account.fetch_and_create_mastodon_account(tag['href'])
      if account.present?
        Mention.find_or_create_by(status: status, account: account) do |m|
          m.silent = false
        end
      end
    end
  end
end
