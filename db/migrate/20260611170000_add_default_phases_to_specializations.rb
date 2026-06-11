class AddDefaultPhasesToSpecializations < ActiveRecord::Migration[7.0]
  def change
    add_reference :specializations, :default_start_phase, foreign_key: { to_table: :phases }, null: true
    add_reference :specializations, :default_end_phase, foreign_key: { to_table: :phases }, null: true
  end
end
