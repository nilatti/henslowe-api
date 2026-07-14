class AddDepartmentToSpecializations < ActiveRecord::Migration[7.2]
  def change
    add_column :specializations, :department_id, :bigint
    add_index :specializations, :department_id
  end
end
