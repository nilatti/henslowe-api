class AllowNullCharacterOnLine < ActiveRecord::Migration[6.1]
  def change
    change_column_null :lines, :character_id, true
  end
end
