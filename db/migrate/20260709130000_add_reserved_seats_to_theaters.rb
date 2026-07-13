class AddReservedSeatsToTheaters < ActiveRecord::Migration[7.2]
  def change
    add_column :theaters, :reserved_seats, :integer, default: 1, null: false
  end
end
