class AddRegularBoolToConflicts < ActiveRecord::Migration[6.1]
  def change
    add_column :conflicts, :regular, :boolean, default: false
  end
end
