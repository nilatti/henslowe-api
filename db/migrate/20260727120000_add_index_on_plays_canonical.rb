class AddIndexOnPlaysCanonical < ActiveRecord::Migration[7.2]
  def change
    add_index :plays, :canonical
  end
end
