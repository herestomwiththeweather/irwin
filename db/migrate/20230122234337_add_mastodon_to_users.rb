class AddMastodonToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :mastodon_identifier, :string, default: ''
    add_column :users, :mastodon_preferred_username, :string, default: ''
    add_column :users, :mastodon_name, :string, default: ''

    add_column :users, :mastodon_following, :string, default: ''
    add_column :users, :mastodon_followers, :string, default: ''
    add_column :users, :mastodon_inbox, :string, default: ''
    add_column :users, :mastodon_outbox, :string, default: ''
    add_column :users, :mastodon_url, :string, default: ''
    add_column :users, :mastodon_icon, :string, default: ''

    add_column :users, :mastodon_summary, :text, default: ''
  end
end
