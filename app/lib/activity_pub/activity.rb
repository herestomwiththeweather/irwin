class ActivityPub::Activity
  def initialize(json, account, recipient_account)
    @json = json
    @account = account
    @recipient_account = recipient_account
  end

  class << self
    def factory(json, account, recipient_account)
      @json = json
      klass&.new(json, account, recipient_account)
    end

    private

    def klass
      case @json['type']
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
      end
    end
  end
end
