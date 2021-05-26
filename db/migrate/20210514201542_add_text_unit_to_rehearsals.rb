class AddTextUnitToRehearsals < ActiveRecord::Migration[6.1]
  def change
    add_column :rehearsals, :text_unit, :string
  end
end
