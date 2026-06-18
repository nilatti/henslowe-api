class AddHeadshotUrlToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :headshot_url, :string
  end
end
