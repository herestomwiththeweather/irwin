class ActivityPub::Activity
  def initialize(json, account, recipient_account)
    @json = json
    @account = account
    @recipient_account = recipient_account
  end

  class << self
    def factory(json, account, recipient_account)
      actor = actor_account(account, json)
      return nil if actor.nil?
      klass(json)&.new(json, actor, recipient_account)
    end

    private

    def actor_account(account, json)
      actor = account

      if json['actor'] != account.identifier
        unless ['Create', 'Update', 'Delete'].include? json['type']
          Rails.logger.info "#{self.name}##{__method__} type: #{json['type']} actor #{json['actor']} does not match signer #{account.identifier}"
          return nil
        end

        if ('Update' == json['type']) && ('Note' != json['object']['type'])
          Rails.logger.info "#{self.name}##{__method__} LD signature rejected for Update: #{json['object']['type']}"
          return nil
        end

        if json['signature'].present?
          Rails.logger.info "#{self.name}##{__method__} type: #{json['type']} validating signature for: #{json['actor']}"
        else
          Rails.logger.info "#{self.name}##{__method__} type: #{json['type']} no signature for: #{json['actor']}"
          return nil
        end

        origin_account = Account.fetch_by_key(json['signature']['creator'])
        if origin_account.nil?
          Rails.logger.info "#{self.name}##{__method__} Error No account for #{json['actor']}"
          return nil
        end

        if origin_account.identifier != json['actor']
          Rails.logger.info "#{self.name}##{__method__} Error #{origin_account.identifier} does not match #{json['actor']}"
          return nil
        end

        return nil unless origin_account.verify_signature(json)
        actor = origin_account

        Rails.logger.info "#{self.name}##{__method__} *** signature verification succeeded *** for actor: #{actor.id}"
      end

      actor
    end

    def klass(json)
      case json['type']
      when 'Accept'
        ActivityPub::Activity::Accept
      when 'Announce'
        ActivityPub::Activity::Announce
      when 'Create'
        ActivityPub::Activity::Create
      when 'Update'
        ActivityPub::Activity::Update
      when 'Delete'
        ActivityPub::Activity::Delete
      when 'Follow'
        ActivityPub::Activity::Follow
      when 'Like'
        ActivityPub::Activity::Like
      when 'Move'
        ActivityPub::Activity::Move
      when 'Reject'
        ActivityPub::Activity::Reject
      when 'Undo'
        ActivityPub::Activity::Undo
      when 'QuoteRequest'
        ActivityPub::Activity::QuoteRequest
      end
    end
  end
end
