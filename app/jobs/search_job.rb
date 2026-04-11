class SearchJob < ApplicationJob
  queue_as :default

  def perform(current_user_id, query_params, page)
    Rails.logger.info "#{self.class}##{__method__} query_params: #{query_params.inspect}"
    statuses = Status.search(query_params).page(page)
    Rails.logger.info "#{self.class}##{__method__} statuses length: #{statuses.length}"
    Turbo::StreamsChannel.broadcast_replace_to ["admin_statuses_channel", User.find(current_user_id).to_gid_param].join(':'),
      target: 'admin_search_with_results',
      partial: 'admin/statuses/search_with_results',
      locals: {
        statuses: statuses,
        query_params: query_params
      }
  end
end
