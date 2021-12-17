class AddCopyStatusToPlay < ActiveRecord::Migration[6.1]
  def change
    add_column :plays, :copy_status, :string
  end
end
