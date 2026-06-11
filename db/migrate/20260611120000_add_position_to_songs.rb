class AddPositionToSongs < ActiveRecord::Migration[7.2]
  def change
    add_column :songs, :position, :integer

    reversible do |dir|
      dir.up do
        FrenchScene.find_each do |fs|
          fs.songs.order(:id).each_with_index do |song, i|
            song.update_column(:position, i + 1)
          end
        end
      end
    end

    change_column_null :songs, :position, false
  end
end
