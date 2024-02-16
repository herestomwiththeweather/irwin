class ActivityPub::Activity::Undo < ActivityPub::Activity
  def perform
    Rails.logger.info "#{self.class}##{__method__}"
    if 'Follow' == @json['object']['type']
      target_account = User.by_actor(@json['object']['object']).account
      Rails.logger.info "#{self.class}##{__method__} undo follow [#{@account.id}, #{target_account.id}, #{@json['object']['id']}]"
      follow = ::Follow.where(target_account: target_account, account: @account).first
      if follow.present?
        Rails.logger.info "#{self.class}##{__method__} Deleting follow #{follow.id} [#{follow.account_id}, #{follow.target_account_id}, #{follow.created_at}, #{follow.uri}]"
        follow.destroy!
      else
        Rails.logger.info "#{self.class}##{__method__} Error. Undo: follow lookup failed."
      end
    elsif 'Like' == @json['object']['type']
      Rails.logger.info "#{self.class}##{__method__} undo like [#{@account.id}, #{@json['object']['object']}]"
      status = Status.from_local_uri(@json['object']['object'])
      like = Like.find_by(status: status, account: @account)
      like.destroy!
    elsif 'Announce' == @json['object']['type']
      uri = @json['object']['id']
      reblog_uri = @json['object']['object']
      Rails.logger.info "#{self.class}##{__method__} undo announce [#{@account.id}], boost of #{reblog_uri}"
      status = Status.find_by(uri: uri)
      status.destroy! if status.present?
    else
      Rails.logger.info "#{self.class}##{__method__} Error. Unsupported type for undo: #{@json['object']['type']}"
    end
    202
  end
end
