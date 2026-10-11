# Writes a new order for the script items (lines, stage directions, sound cues)
# of one or more French scenes in a play. Items can move between the listed
# French scenes; each listed French scene ends up holding exactly the items
# listed for it, positioned 1..n in that order. Labels (number) never change.
#
# A line that lands in a different French scene adds its speaker to that French
# scene's on-stage list if they aren't already there. Nothing is removed from
# the French scene it left — the speaker may still be on stage without lines.
class ReorderScriptItems
  class InvalidOrder < StandardError; end

  MODELS = { 'line' => Line, 'stage_direction' => StageDirection, 'sound_cue' => SoundCue }.freeze

  # french_scenes: [{ id:, items: [{ type:, id: }] }]
  def initialize(play:, french_scenes:)
    @play = play
    @french_scenes = french_scenes.map do |fs|
      { id: fs[:id].to_i, items: Array(fs[:items]).map { |i| [i[:type].to_s, i[:id].to_i] } }
    end
  end

  def run
    validate!
    ActiveRecord::Base.transaction do
      moved_lines = lines_changing_french_scene
      @french_scenes.each { |fs| write_positions(fs) }
      add_speakers_to_on_stages(moved_lines)
    end
  end

  private

  def french_scene_ids
    @french_scene_ids ||= @french_scenes.map { |fs| fs[:id] }
  end

  def all_items
    @all_items ||= @french_scenes.flat_map { |fs| fs[:items] }
  end

  def ids_of(type)
    all_items.select { |t, _| t == type }.map(&:last)
  end

  def validate!
    raise InvalidOrder, 'No French scenes given' if @french_scenes.empty?
    raise InvalidOrder, 'A French scene is listed twice' if french_scene_ids.uniq.size != french_scene_ids.size
    raise InvalidOrder, 'An item is listed twice' if all_items.uniq.size != all_items.size

    unknown_types = all_items.map(&:first).uniq - MODELS.keys
    raise InvalidOrder, "Unknown item type: #{unknown_types.join(', ')}" if unknown_types.any?

    play_french_scene_ids = FrenchScene.unscoped.joins(scene: :act)
      .where(acts: { play_id: @play.id }, id: french_scene_ids).pluck(:id)
    raise InvalidOrder, 'French scene not found in this play' if play_french_scene_ids.size != french_scene_ids.size

    MODELS.each do |type, model|
      listed = ids_of(type)
      in_play = model.joins(french_scene: { scene: :act }).where(acts: { play_id: @play.id }, id: listed).count
      raise InvalidOrder, "#{type.humanize} not found in this play" if in_play != listed.size

      # Every item currently in a listed French scene must be placed somewhere,
      # or it would be left with a stale position among the new ones.
      left_out = model.where(french_scene_id: french_scene_ids).pluck(:id) - listed
      raise InvalidOrder, 'The new order must include every item in the listed French scenes' if left_out.any?
    end
  end

  def lines_changing_french_scene
    destination = {}
    @french_scenes.each do |fs|
      fs[:items].each { |type, id| destination[id] = fs[:id] if type == 'line' }
    end
    Line.where(id: destination.keys).select { |line| line.french_scene_id != destination[line.id] }
      .map { |line| [line, destination[line.id]] }
  end

  def write_positions(fs)
    fs[:items].each_with_index.group_by { |(type, _), _| type }.each do |type, entries|
      whens = entries.map { |(_, id), index| "WHEN #{id.to_i} THEN #{index + 1}" }.join(' ')
      MODELS[type].where(id: entries.map { |(_, id), _| id })
        .update_all(["french_scene_id = ?, position = CASE id #{whens} END", fs[:id]])
    end
  end

  def add_speakers_to_on_stages(moved_lines)
    moved_lines.each do |line, french_scene_id|
      if line.character_id
        OnStage.find_or_create_by!(french_scene_id: french_scene_id, character_id: line.character_id)
      elsif line.character_group_id
        OnStage.find_or_create_by!(french_scene_id: french_scene_id, character_group_id: line.character_group_id)
      end
    end
  end
end
