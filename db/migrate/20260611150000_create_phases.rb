class CreatePhases < ActiveRecord::Migration[7.0]
  def change
    create_table :phases do |t|
      t.string :name, null: false
      t.integer :position
      t.timestamps
    end
  end
end
