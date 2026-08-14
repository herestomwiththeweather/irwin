class AddQuoteRequestUriToQuotes < ActiveRecord::Migration[7.1]
  def change
    add_column :quotes, :quote_request_uri, :string, null: true, default: nil
  end
end
