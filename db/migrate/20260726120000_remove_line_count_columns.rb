class RemoveLineCountColumns < ActiveRecord::Migration[7.2]
  def change
    %i[plays acts scenes french_scenes lines].each do |table|
      remove_column table, :original_line_count, :float
      remove_column table, :new_line_count, :float
    end
    remove_column :characters, :original_line_count, :integer
    remove_column :characters, :new_line_count, :integer
  end
end
