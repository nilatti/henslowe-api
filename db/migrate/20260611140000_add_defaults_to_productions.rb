class AddDefaultsToProductions < ActiveRecord::Migration[7.0]
  def change
    add_reference :productions, :default_space, foreign_key: { to_table: :spaces }, null: true

    create_table :production_default_calls, id: false do |t|
      t.bigint :production_id, null: false
      t.bigint :user_id, null: false
    end
    add_index :production_default_calls, [:production_id, :user_id], unique: true
  end
end
