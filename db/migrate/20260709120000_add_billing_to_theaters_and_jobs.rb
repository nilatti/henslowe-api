class AddBillingToTheatersAndJobs < ActiveRecord::Migration[7.2]
  def change
    add_column :theaters, :stripe_customer_id, :string
    add_column :theaters, :subscription_status, :string
    add_column :theaters, :subscription_end_date, :datetime

    add_column :jobs, :theater_sponsored, :boolean, default: false, null: false
  end
end
