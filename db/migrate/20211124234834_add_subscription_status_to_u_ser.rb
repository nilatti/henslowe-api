class AddSubscriptionStatusToUSer < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :subscription_status, :string, default: 'never subscribed'
  end
end
