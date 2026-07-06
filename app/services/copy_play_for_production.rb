class CopyPlayForProduction
  attr_accessor :original_play, :production_id, :new_play

  def initialize(play_id:, production_id:)
    @original_play = Play.includes(
      :characters, :character_groups,
      acts: { scenes: { french_scenes: [
        :lines, :on_stages, :sound_cues,
        stage_directions: [:characters, :character_groups]
      ] } }
    ).find(play_id)
    @production_id = production_id
    @character_map = {}
    @character_group_map = {}
  end

  def run
    ActiveRecord::Base.transaction(requires_new: true) do
      create_play_copy(play: @original_play)
      CreateCastingForProduction.new(play_id: @new_play.id, production_id: production_id).create_castings
      @new_play.production_copy_complete = true
      @new_play.copy_status = "Copying script complete"
      @new_play.save!
    end
  end

  def create_play_copy(play:)
    @new_play = @original_play.dup
    @new_play.canonical = false
    @new_play.production_id = @production_id
    @new_play.original_play_id = @original_play.id
    @new_play.copy_status = 'Copying characters'
    @new_play.save!
    create_copies_of_each_character(original_play_characters: @original_play.characters, new_play: @new_play)
    create_copies_of_each_character_group(original_play_character_groups: @original_play.character_groups, new_play: @new_play)
    @new_play.copy_status = "Copying play text and structure"
    create_copies_of_each_act(original_play: @original_play, new_play: @new_play)
  end

  def create_copies_of_each_act(original_play:, new_play:)
    original_play.acts.each do |original_act|
      puts "Duplicating act #{original_act.id}"
      new_act = original_act.dup
      new_act.play = new_play
      new_act.save!
      create_copies_of_each_scene(original_act: original_act, new_act: new_act)
    end
  end

  def create_copies_of_each_character(original_play_characters:, new_play:)
    original_play_characters.each do |original_character|
      new_character = original_character.dup
      new_character.play = new_play
      new_character.name = fallback_name(original_character.name, original_character.xml_id)
      new_character.save!
      @character_map[original_character.id] = new_character
    end
  end

  def create_copies_of_each_character_group(original_play_character_groups:, new_play:)
    original_play_character_groups.each do |original_character_group|
      new_character_group = original_character_group.dup
      new_character_group.play = new_play
      new_character_group.name = fallback_name(original_character_group.name, original_character_group.xml_id)
      new_character_group.save!
      @character_group_map[original_character_group.id] = new_character_group
    end
  end

  # Some legacy TEI-imported characters/character_groups have no name, only an
  # xml_id (e.g. "ATTENDANTS.OLIVIA_TN") — derive a readable name so the copy's
  # presence validation doesn't block the whole script copy on old data.
  def fallback_name(name, xml_id)
    return name if name.present?
    return "Unnamed" if xml_id.blank?
    xml_id.sub(/_[A-Za-z0-9]+\z/, '').tr('.', ' ').split(/[\s_]+/).map(&:capitalize).join(' ')
  end

  def create_copies_of_each_scene(original_act:, new_act:)
    original_act.scenes.each do |original_scene|
      puts "Duplicating scene #{original_scene.id}"
      new_scene = original_scene.dup
      new_scene.act = new_act
      new_scene.save!
      create_copies_of_each_french_scene(original_scene: original_scene, new_scene: new_scene)
    end
  end

  def create_copies_of_each_french_scene(original_scene:, new_scene:)
    original_scene.french_scenes.each do |original_french_scene|
      puts "Duplicating french scene #{original_french_scene.id}"
      new_french_scene = original_french_scene.dup
      new_french_scene.scene = new_scene
      new_french_scene.save!
      create_copies_of_each_line(original_french_scene: original_french_scene, new_french_scene: new_french_scene)
      create_copies_of_each_on_stage(original_french_scene: original_french_scene, new_french_scene: new_french_scene)
      create_copies_of_each_sound_cue(original_french_scene: original_french_scene, new_french_scene: new_french_scene)
      create_copies_of_each_stage_direction(original_french_scene: original_french_scene, new_french_scene: new_french_scene)
    end
  end

  def create_copies_of_each_line(original_french_scene:, new_french_scene:)
    original_french_scene.lines.each do |original_line|
      new_line = original_line.dup
      new_line.french_scene = new_french_scene
      if original_line.character_id
        new_line.character = @character_map[original_line.character_id]
      elsif original_line.character_group_id
        new_line.character_group = @character_group_map[original_line.character_group_id]
      end
      new_line.save!
    end
  end

  def create_copies_of_each_on_stage(original_french_scene:, new_french_scene:)
    original_french_scene.on_stages.each do |original_on_stage|
      new_on_stage = original_on_stage.dup
      new_on_stage.french_scene = new_french_scene
      if original_on_stage.character_id
        new_on_stage.character = @character_map[original_on_stage.character_id]
      elsif original_on_stage.character_group_id
        new_on_stage.character_group = @character_group_map[original_on_stage.character_group_id]
      end
      new_on_stage.save!
    end
  end

  def create_copies_of_each_sound_cue(original_french_scene:, new_french_scene:)
    original_french_scene.sound_cues.each do |original_sound_cue|
      new_sound_cue = original_sound_cue.dup
      new_sound_cue.french_scene = new_french_scene
      new_sound_cue.save!
    end
  end

  def create_copies_of_each_stage_direction(original_french_scene:, new_french_scene:)
    original_french_scene.stage_directions.each do |original_stage_direction|
      new_stage_direction = original_stage_direction.dup
      new_stage_direction.french_scene = new_french_scene
      # .characters / .character_groups already loaded in memory via includes()
      if original_stage_direction.characters.any?
        new_stage_direction.characters = original_stage_direction.characters.map { |c| @character_map[c.id] }.compact
      elsif original_stage_direction.character_groups.any?
        new_stage_direction.character_groups = original_stage_direction.character_groups.map { |cg| @character_group_map[cg.id] }.compact
      end
      new_stage_direction.save!
    end
  end
end
