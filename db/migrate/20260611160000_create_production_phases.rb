class CreateProductionPhases < ActiveRecord::Migration[7.0]
  def change
    create_table :production_phases do |t|
      t.references :production, null: false, foreign_key: true
      t.references :phase, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.timestamps
    end
    add_index :production_phases, [:production_id, :phase_id], unique: true
  end
end
