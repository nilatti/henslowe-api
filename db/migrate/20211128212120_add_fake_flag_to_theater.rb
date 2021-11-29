class AddFakeFlagToTheater < ActiveRecord::Migration[6.1]
  def change
    add_column :theaters, :fake, :boolean, default: false
  end
end
