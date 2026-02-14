require 'rails_helper'

RSpec.describe MoveJob, type: :job do
  describe '#perform' do
    it 'returns without processing when matches_activity_actor? is false' do
      account = create(:account)
      recipient_account = create(:account)
      wrong_actor = 'https://example.com/wrong_actor'

      expect(Account).not_to receive(:fetch_and_create_or_update_mastodon_account)

      MoveJob.perform_now(account.id, recipient_account.id, wrong_actor, 'https://example.com/target', 'https://example.com/activity/1')
    end
  end
end
