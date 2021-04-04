class MakeUserAndSpaceOptionalOnConflictPattern < ActiveRecord::Migration[6.1]
  def change
    change_column_null :conflict_patterns, :user_id, true
    change_column_null :conflict_patterns, :space_id, true
  end
end
