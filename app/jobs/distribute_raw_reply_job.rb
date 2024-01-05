class DistributeRawReplyJob < ApplicationJob
  queue_as :default

  def perform(raw_json, account_id, actor_id)
    account = Account.find(account_id)
    user = account.user
    Rails.logger.info "#{account.webfinger_to_s} distributing reply from account #{actor_id}"
    
    account.account_followers.each do |follower|
      if follower.id != actor_id
        json_response = HttpClient.new(follower.inbox, user.actor_url, user.private_key, raw_json).post
        if json_response['error']&.present?
          Rails.logger.info "DistributeRawReply error: #{json_status['error']}"
        end
      end
    end
  end
end
