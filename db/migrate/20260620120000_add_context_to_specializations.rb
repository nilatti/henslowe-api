class AddContextToSpecializations < ActiveRecord::Migration[7.1]
  def change
    add_column :specializations, :context, :integer, default: 2, null: false
  end
end
