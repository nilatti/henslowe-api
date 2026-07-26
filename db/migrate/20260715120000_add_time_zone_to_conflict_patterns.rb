class AddTimeZoneToConflictPatterns < ActiveRecord::Migration[7.2]
  def change
    add_column :conflict_patterns, :time_zone, :string
  end
end
