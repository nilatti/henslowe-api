class AddDefaultRehearsalLengthsToProductions < ActiveRecord::Migration[7.2]
  def change
    add_column :productions, :default_rehearsal_block_length, :integer
    add_column :productions, :default_rehearsal_break_length, :integer
  end
end
