class Quote < ApplicationRecord
  enum :state, { pending: 0, accepted: 1, rejected: 2, revoked: 3, deleted: 4 }

  APPROVAL_POLICY_FLAGS = {
    unsuported_policy: 1,
    public: 2,
    followers: 4,
    following: 8,
  }.freeze

  belongs_to :account
  belongs_to :status
  belongs_to :quoted_account, class_name: 'Account', optional: true
  belongs_to :quoted_status, class_name: 'Status', optional: true

  def verify!
    if URI(approval_uri).host != URI(quoted_account.identifier).host
      Rails.logger.info "#{self.class}##{__method__} error quote #{self.id} approval_uri domain does not match quoted_account domain"
      return false
    end

    json_authorization = User.representative.get(approval_uri)
    if nil == json_authorization
      Rails.logger.info "#{self.class}##{__method__} error fetching quote #{self.id} authorization"
      return false
    end

    if json_authorization['error'].present?
      Rails.logger.info "#{self.class}##{__method__} error fetching quote #{self.id} authorization: #{json_status['error']}"
      return false
    end

    if status.uri != json_authorization['interactingObject']
      Rails.logger.info "#{self.class}##{__method__} error quote #{self.id} received interactingObject: #{json_status['interactingObject']}"
      return false
    end

    if quoted_status.uri != json_authorization['interactionTarget']
      Rails.logger.info "#{self.class}##{__method__} error quote #{self.id} received interactionTarget: #{json_status['interactionTarget']}"
      return false
    end

    if quoted_account.identifier != json_authorization['attributedTo']
      Rails.logger.info "#{self.class}##{__method__} error quote #{self.id} received attributedTo: #{json_status['attributedTo']}"
      return false
    end

    Rails.logger.info "#{self.class}##{__method__} authorization verified for quote #{self.id}."

    self.update_attribute(:state, :accepted)

    true
  end
end
