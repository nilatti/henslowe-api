class DropDoorkeepertTables < ActiveRecord::Migration[6.1]
  def change
    drop_table :oauth_applications
    drop_table :oauth_access_tokens
    drop_table :oauth_access_grants
  end
end
