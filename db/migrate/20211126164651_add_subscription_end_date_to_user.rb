class AddSubscriptionEndDateToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :subscription_end_date, :date
  end
end
