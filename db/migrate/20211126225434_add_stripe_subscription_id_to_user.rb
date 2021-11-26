class AddStripeSubscriptionIdToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :stripe_subscription_id, :string
  end
end
