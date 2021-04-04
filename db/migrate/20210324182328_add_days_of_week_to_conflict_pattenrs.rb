class AddDaysOfWeekToConflictPattenrs < ActiveRecord::Migration[6.1]
  def change
    add_column :conflict_patterns, :days_of_week, :string
  end
end
