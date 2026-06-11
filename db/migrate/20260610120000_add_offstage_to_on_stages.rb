class AddOffstageToOnStages < ActiveRecord::Migration[7.0]
  def change
    add_column :on_stages, :offstage, :boolean, default: false
  end
end
