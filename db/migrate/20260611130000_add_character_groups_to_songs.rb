class AddCharacterGroupsToSongs < ActiveRecord::Migration[7.2]
  def change
    create_table :character_groups_songs, id: false do |t|
      t.references :song, null: false, foreign_key: true
      t.references :character_group, null: false, foreign_key: true
    end

    add_index :character_groups_songs, [:song_id, :character_group_id], unique: true
  end
end
