class RemoveMastodonFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :mastodon_identifier
    remove_column :users, :mastodon_preferred_username
    remove_column :users, :mastodon_name

    remove_column :users, :mastodon_following
    remove_column :users, :mastodon_followers
    remove_column :users, :mastodon_inbox
    remove_column :users, :mastodon_outbox
    remove_column :users, :mastodon_url
    remove_column :users, :mastodon_icon

    remove_column :users, :mastodon_summary
  end
end
