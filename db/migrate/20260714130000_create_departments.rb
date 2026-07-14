class CreateDepartments < ActiveRecord::Migration[7.2]
  def change
    create_table :departments do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end
  end
end
