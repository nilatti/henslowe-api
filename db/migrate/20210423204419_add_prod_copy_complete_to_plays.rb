class AddProdCopyCompleteToPlays < ActiveRecord::Migration[6.1]
  def change
    add_column :plays, :production_copy_complete, :boolean, default: false
  end
end
