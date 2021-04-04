class AddConflictPatternRefToConflicts < ActiveRecord::Migration[6.1]
  def change
    add_reference :conflicts, :conflict_pattern, null: true, foreign_key: true
  end
end
