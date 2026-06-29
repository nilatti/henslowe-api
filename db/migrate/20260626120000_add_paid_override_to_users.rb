class AddPaidOverrideToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :paid_override, :boolean, default: false, null: false
  end
end
