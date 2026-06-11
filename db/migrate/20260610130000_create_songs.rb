class CreateSongs < ActiveRecord::Migration[7.2]
  def change
    create_table :songs do |t|
      t.references :french_scene, null: false, foreign_key: true
      t.string :title, null: false
      t.timestamps
    end

    create_table :characters_songs, id: false do |t|
      t.references :song, null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true
    end

    add_index :characters_songs, [:song_id, :character_id], unique: true
  end
end
