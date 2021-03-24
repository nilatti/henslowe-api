class AddSpecializationAdminBools < ActiveRecord::Migration[6.1]
  def change
    add_column :specializations, :production_admin, :boolean, default: false
    add_column :specializations, :theater_admin, :boolean, default: false
  end
end
