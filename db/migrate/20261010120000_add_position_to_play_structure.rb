# Acts, scenes and French scenes get a position (their order in the play)
# separate from their number (their label), so they can be reordered without
# relabeling. The structure tables are small, so they're backfilled here from
# today's number order.
#
# Lines, stage directions and sound cues share one position sequence within a
# French scene. Those tables are large and this migration runs during ECS task
# boot, so they are NOT backfilled: position stays null (sort by number, as
# before) until someone reorders that French scene, which writes every item's
# position at once. Nullable columns appended to the table are an instant
# ALTER in MySQL 8, so this doesn't rewrite the big tables either.
class AddPositionToPlayStructure < ActiveRecord::Migration[7.2]
  def up
    add_column :acts, :position, :integer
    add_column :scenes, :position, :integer
    add_column :french_scenes, :position, :integer
    add_column :lines, :position, :integer
    add_column :stage_directions, :position, :integer
    add_column :sound_cues, :position, :integer

    backfill :acts, partition: :play_id
    backfill :scenes, partition: :act_id
    backfill :french_scenes, partition: :scene_id
  end

  def down
    remove_column :acts, :position
    remove_column :scenes, :position
    remove_column :french_scenes, :position
    remove_column :lines, :position
    remove_column :stage_directions, :position
    remove_column :sound_cues, :position
  end

  private

  def backfill(table, partition:)
    execute <<~SQL
      UPDATE #{table}
      JOIN (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY #{partition} ORDER BY number, id) AS rn
        FROM #{table}
      ) ordered ON ordered.id = #{table}.id
      SET #{table}.position = ordered.rn
    SQL
  end
end
