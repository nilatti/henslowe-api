# before importing, you must remove the TEI tags from the xml document and replace them with <root> tags. Also, make a character called "Could Not Find Character" with xml_id: "CouldNotFindCharacter" in the xml document

class ImportFromFolgerXmlAll
  attr_accessor :characters,
    :character_groups,
    :current_act,
    :current_character,
    :current_characters_onstage,
    :current_french_scene,
    :current_scene,
    :db_characters,
    :db_character_groups,
    :lines,
    :on_stages,
    :play,
    :parsed_xml,
    :stage_directions,
    :updated_words,
    :words

  def initialize(text_file)
    xml_doc = File.read(text_file) # for Folger Digital Texts, must remove the TEI tags at beginning and end
    @parsed_xml = Nokogiri::XML.parse(xml_doc)
    @characters = []
    @character_groups = []
    @current_character = []
    @current_characters_onstage = []
    @db_characters = []
    @db_character_groups = []
    @lines = []
    @on_stages = []
    @play
    @stage_directions = []
    @updated_words = []
    @words = []
  end


  def run
    puts "started run at #{Time.current()}"
    @play = build_play(global_parsed_xml: @parsed_xml)
    puts "returned"
    puts (@play.id)
    build_characters(play: @play)
    puts "finished building characters at #{Time.current()}"
    @db_characters = @play.characters
    build_acts(play: @play, parsed_xml: @parsed_xml)
    ActiveRecord::Base.connection_pool.with_connection do
      Line.import @lines, on_duplicate_key_ignore: true
    end
    ActiveRecord::Base.connection_pool.with_connection do
      StageDirection.import @stage_directions, on_duplicate_key_ignore: true
    end
    ActiveRecord::Base.connection_pool.with_connection do
      OnStage.import @on_stages, on_duplicate_key_ignore: true
    end
    ActiveRecord::Base.connection_pool.with_connection do
      Word.import @words, on_duplicate_key_ignore: true
    end
    puts Time.current
    connect_lines_to_words(play: @play)
    build_lines_content(@play.lines)
    check_on_stages(french_scenes: @play.french_scenes)
  end

  def build_acts(
    play:,
    parsed_xml:,
    global_tracking_of_play_characters: nil,
    global_tracking_of_play_character_groups: nil
  )
    puts "build acts called"
    @parsed_xml.xpath('//div1').each do |act|
      puts "building act #{act.attr('xml:id')}"
      if act.attr('type') === 'act'
        heading = build_header(item: act.at_xpath('head'))
        puts "building #{heading} at #{Time.current}"
        @current_act = Act.create(
          heading: heading,
          number: act.attr('n'),
          play_id: play.id
        )
        scenes = act.xpath('div2')
        scenes.each do |scene|
          if scene.attr('type') === 'epilogue'
            @current_act = Act.create(
              heading: 'EPILOGUE',
              number: 6,
              play_id: play.id
            )
          elsif scene.attr('type') === 'prologue'
            @current_act = Act.create(
              heading: 'PROLOGUE',
              number: 0,
              play_id: play.id
            )
          end
          build_scene(
            act: @current_act,
            scene: scene,
            global_tracking_of_play_characters: global_tracking_of_play_characters,
            global_tracking_of_play_character_groups: global_tracking_of_play_character_groups
          )
        end
      end
    end
    return @current_act
  end

  def build_character(
      character:,
      play:,
      global_tracking_of_play_characters: nil,
      global_tracking_of_play_character_groups: nil
    )
    char_tracking = global_tracking_of_play_characters || @characters
    cg_lookup = global_tracking_of_play_character_groups || @db_character_groups
    character_group = ''
    if character.attr('corresp')
      corresp_string = character.attr('corresp').to_s.sub('#','')
      character_group = cg_lookup.find {|cg| cg.xml_id == corresp_string}
    end
    name = ''
    unless (character.xpath('persName/name').text).blank?
      name = character.xpath('persName/name').text
    else
      name = character.attr('xml:id')
    end
    character = Character.new(
      corresp: character.attr('corresp'),
      description: character.xpath('state').text,
      gender: character.xpath('sex').text,
      name: name,
      play_id: play.id,
      xml_id: character.attr('xml:id')
    )
    if character_group.class == CharacterGroup
      character.character_group = character_group
    end
    char_tracking << character
    return character
  end

  def build_character_group(character_group:, play:, global_tracking_of_play_character_groups: nil)
    character_group = CharacterGroup.new(
      corresp: character_group.attr('corresp'),
      play_id: play.id,
      xml_id: character_group.attr('xml:id')
    )
    tracking = global_tracking_of_play_character_groups || @character_groups
    tracking << character_group
    return character_group
  end

  def build_characters(
      play:,
      global_parsed_xml: @parsed_xml,
      global_tracking_of_play_characters: nil,
      global_tracking_of_play_character_groups: nil
    )
    cg_tracking = global_tracking_of_play_character_groups || @character_groups
    char_tracking = global_tracking_of_play_characters || @characters
    puts "play is #{play.id}"
    character_groups = global_parsed_xml.xpath('//personGrp')
    puts (character_groups)
    character_groups.each {|cg| build_character_group(character_group: cg, play: play, global_tracking_of_play_character_groups: cg_tracking)}
    CharacterGroup.import cg_tracking, on_duplicate_key_ignore: true
    @db_character_groups = play.character_groups
    characters = global_parsed_xml.xpath('//person')
    characters.each {|c| build_character(character: c, play: play, global_tracking_of_play_characters: char_tracking, global_tracking_of_play_character_groups: cg_tracking)}
    Character.import char_tracking, on_duplicate_key_ignore: true
    @db_characters = play.characters
    return @db_characters
  end

  def build_french_scene(french_scene_number:, scene:, play: nil)
    @current_french_scene = FrenchScene.create(
      number: french_scene_number,
      scene: scene
    )
    return @current_french_scene
  end

  def build_header(item:)
    heading = ''
    if item
      item.children.map(&:text).each do |piece|
        piece.chomp!
        heading << piece
      end
    end
    return heading
  end

  def build_line(character:, line:, french_scene:) #expects array of characters
    puts "inside build line, character: #{character}"
    new_line = ''
    if line.attr('ana')
      if character
        puts "character array! #{character}"
        character.each do |char|
          puts "character #{char.name}"
          ana = line.attr('ana') || ''
          corresp = line.attr('corresp') || ''
          number = line.attr('n') || ''
          xml_id = line.attr('xml:id') || ''
          new_line = Line.new(
            ana: ana,
            character_id: char.id,
            corresp: corresp,
            french_scene_id: french_scene.id,
            number: number,
            kind: 'line',
            xml_id: xml_id,
          )
          @lines << new_line
        end
      else
        ana = line.attr('ana') || ''
        corresp = line.attr('corresp') || ''
        number = line.attr('n') || ''
        xml_id = line.attr('xml:id') || ''
        new_line = Line.new(
          ana: ana,
          corresp: corresp,
          french_scene_id: french_scene.id,
          number: number,
          kind: 'line',
          xml_id: xml_id,
        )
      end
    else
      puts "this didn't have an attr #{line}"
    end
    return new_line
  end

  def build_lines_content(lines)
    lines.each do |line|
      content = ''
      line.words.each do |word|
        content += word.content
      end
      line.original_content = content
      line.save
    end
  end


  def build_on_stages(french_scene:, characters:, global_tracking_of_on_stages: nil) #expect characters from parser, so [0] = characters, [1] = character groups
    tracking = global_tracking_of_on_stages || @on_stages
    characters.flatten!(4)
    characters.uniq!
    characters.each do |char|
      if char.is_a? Character
        tracking << OnStage.new(french_scene: french_scene, character: char, category: 'Character')
      elsif char.is_a? CharacterGroup
        tracking << OnStage.new(french_scene: french_scene, character_group: char, category: 'Character')
      else
        puts "didn't match on class: #{char}"
      end
    end
    return tracking
  end

  def build_play(global_parsed_xml: @parsed_xml)
    synopsis = global_parsed_xml.xpath('//div[@type="synopsis"]') || ''
    title = global_parsed_xml.xpath('//titleStmt/title').text
    author = Author.find_by(last_name: 'Shakespeare') || ''
    text_notes = "Adapted from the Folger Digital Texts, edited by "
    editors = global_parsed_xml.xpath('//titleStmt/editor').map(&:text).join(', ')
    text_notes << editors
    ActiveRecord::Base.connection_pool.with_connection do
      global_play = Play.create(author: author, canonical: true, synopsis: synopsis, text_notes: text_notes, title: title)
      return global_play
    end
  end

  def build_scene(
    act:,
    scene:,
    play: nil,
    global_tracking_of_play_characters: nil,
    global_tracking_of_play_character_groups: nil
    )
    @current_characters_on_stage = []
    scene_number = scene.attr('n') || 0
    heading = build_header(item: scene.at_xpath('head'))
    puts "header is #{heading}"
    @current_scene = Scene.create(
      act: act,
      heading: heading,
      number: scene_number
    )
    puts "current scene is #{@current_scene.number}"
    @current_french_scene = build_french_scene(
      french_scene_number: 'a',
      scene: @current_scene
    )
    stage_directions = [] #need to grab all stage directions so that we don't make extra french scenes. The scene autocreates the first french scene and we don't want one made from the final exit.
    scene.traverse do |node|
      if node.matches?('stage')
        stage_directions << node
      end
    end
    scene.children.select(&:element?).each do |item|
      if item.matches?('stage')
        puts "item is stage direction"
        if (item != stage_directions.first && item != stage_directions.last) && (item.attr('type') === 'entrance' || item.attr('type') === 'exit') #if it's not the first or last entrance or exit, let's make a french scene!
          puts "it's not first or last and it's an entrance or exit, so let's make a french scene"
          @current_french_scene = build_french_scene(
            french_scene_number: @current_french_scene.number.next,
            scene: @current_scene
          )
        end
      end
      process_item(item)
    end
    return @current_scene
  end


  def build_sound_cue(french_scene:, item:)
    content = extract_content(item: item)
    ActiveRecord::Base.connection_pool.with_connection do
      SoundCue.create(
        original_content: content,
        french_scene_id: french_scene.id,
        line_number: item.attr('n'),
        notes: item.attr('ana'),
        kind: item.attr('type'),
        xml_id: item.attr('xml:id')
      )
    end
  end

  def build_speech(french_scene:, item:)
    puts "building speech"
    @current_character = []
    character_parser = extract_characters_from_xml_id_string(xml_ids: item.attr('who'))
    @current_character = character_parser.flatten!(3)
    puts "at global: #{@current_character}"
  end

  def build_stage_direction(item:, global_tracking_of_current_french_scene: nil, global_tracking_of_play_characters: nil, global_tracking_of_play_character_groups: nil)
    current_fs = global_tracking_of_current_french_scene || @current_french_scene
    puts item
    character_parser = extract_characters_from_xml_id_string(
      xml_ids: item.attr('who'),
      global_tracking_of_play_characters: global_tracking_of_play_characters,
      global_tracking_of_play_character_groups: global_tracking_of_play_character_groups
    )
    puts "333 #{character_parser.length}"
    content = extract_content(item: item)
    characters = character_parser[0]
    character_groups = character_parser[1]
    if item.attr('type') == 'entrance' || item.attr('type') == 'exit'
      puts "333 #{item.attr('type')}"
      track_onstage_characters(french_scene: current_fs, stage_direction: item, characters: character_parser)
      puts "335 #{character_parser.size}"
    end
    puts "338 #{character_parser.length}"
    stage_direction = StageDirection.new(
      characters: characters,
      character_groups: character_groups,
      original_content: content,
      french_scene_id: current_fs.id,
      number: item.attr('n'),
      kind: item.attr('type'),
      xml_id: item.attr('xml:id')
    )
    @stage_directions << stage_direction
    return stage_direction
  end

  def build_word(word:, play: nil)
    current_play = play || self.play
    kind = ''
    if word.matches?('w')
      kind = 'word'
    elsif word.matches?('pc')
      kind = 'punctuation'
    elsif word.matches?('c')
      kind = 'space'
    end
    new_word = Word.new(
      content: word.text,
      line_number: word.attr('n'),
      kind: kind,
      play_id: current_play.id,
      xml_id: word.attr('xml:id')
    )
    @words << new_word
    return new_word
  end

  def check_on_stages(french_scenes:)
    french_scenes.each do |french_scene|
      uniq_on_stages = french_scene.on_stages.uniq { |o| o.character_id }
      duplicates = french_scene.on_stages - uniq_on_stages
      duplicates.each { |o| o.destroy }

      speaking_characters = french_scene.lines.map { |line| line.character_id}.to_set
      on_stage_characters = french_scene.on_stages.map {|on_stage| on_stage.character_id}.to_set
      speaking_but_not_on_stage = speaking_characters - on_stage_characters
      speaking_but_not_on_stage.each do |character|
        ActiveRecord::Base.connection_pool.with_connection do
          OnStage.create(character_id: character, french_scene_id: french_scene.id, category: 'Character')
        end
      end
      on_stage_but_not_speaking = on_stage_characters - speaking_characters
      on_stage_but_not_speaking.each do |character|
        ActiveRecord::Base.connection_pool.with_connection do
          o = OnStage.find_by(character_id: character, french_scene_id: french_scene.id)
          o.nonspeaking = true
          o.save
        end
      end
    end
  end

  def connect_lines_to_words(play:)
    lines = play.lines
    words = play.words.to_set
    lines.each do |line|
      line_arr = line.corresp.to_s.split(' ')
      line_arr.each do |xml_id|
        xml_id.sub!('#', '')
        word = words.find {|w| w.xml_id == xml_id}
        if word
          updated_word = {
            created_at: word.created_at,
            content: word.content,
            id: word.id,
            kind: word.kind,
            line_id: line.id,
            line_number: line.number,
            play_id: word.play_id,
            xml_id: word.xml_id,
            updated_at: word.updated_at,
          }
          @updated_words << updated_word
        else
          puts "cant find this word: #{xml_id}"
        end
      end
    end
    ActiveRecord::Base.connection_pool.with_connection do
      Word.upsert_all(@updated_words)
    end
  end

  def determine_type_of_item(
      item:
    )
    if item.matches?('sp')
      build_speech(french_scene: @current_french_scene, item: item)
    elsif item.matches?('stage')
      build_stage_direction(item: item)
    elsif item.matches?('sound')
      build_sound_cue(french_scene: @current_french_scene, item: item)
    elsif item.matches?('head')
      build_header(item: item)
    elsif item.matches?('milestone') && (item.attr('unit') === 'ftln' || item.attr('unit') === 'line')
      build_line(character: @current_character, french_scene: @current_french_scene, line: item)
    elsif item.matches?('w') || item.matches?('c') || item.matches?('pc') || item.matches?('speaker')
      build_word(word: item)
    elsif item.matches?('lb') || item.matches?('q') || item.matches?('foreign') || item.matches?('ab') || item.matches?('seg')||item.matches?('label') #all junk we don't need to track, just get the children.
      puts 'this is not one of those'
    else
      puts "couldn't match item #{item}"
    end
  end

  def extract_characters_from_xml_id_string(xml_ids:, global_tracking_of_play_characters: nil, global_tracking_of_play_character_groups: nil) #should return array that contains two arrays character_parser = [[characters], [character_groups]]
    char_lookup = global_tracking_of_play_characters || @db_characters
    cg_lookup = global_tracking_of_play_character_groups || @db_character_groups
    character_parser = [[],[]]
    xml_id_arr = xml_ids.to_s.split(' ')

    xml_id_arr.each do |xml_id|
      xml_id.sub!('#', '')
      character = char_lookup.find { |c| c.xml_id == xml_id }
      character_group = cg_lookup.find { |c| c.xml_id == xml_id }
      if character
        character_parser[0] << character
      elsif character_group
        character_parser[1] << character_group
      else
        puts "Could not find character #{xml_id}"
        character_parser[0] << char_lookup.find { |character| character.xml_id == 'CouldNotFindCharacter' }
      end
    end
    puts "467 #{character_parser}\n#{character_parser.size}"
    return character_parser
  end

  def extract_content(item:)
    content = ''
    item.children.each do |child|
      if child.matches?('w') || child.matches?('pc') || child.matches?('c')
        content << child.text
      end
    end
    content
  end

  def extract_items_from_corresp(corresp)
    corresp_arr = corresp.to_s.split(' ')
    corresp_arr.each do |corresp|
      corresp.sub!('#', '')
      xml_word = @parsed_xml.at_xpath("//*[@xml:id=\"#{corresp}\"]")
    end
  end
  def process_item(
    item
  )
    determine_type_of_item(
      item: item,
    )
    if verify_no_more_children(item)
      return
    else
      item.children.select(&:element?).each {|child| process_item(child)}
    end
  end

  def track_onstage_characters(
    french_scene:,
    stage_direction:,
    characters:,
    global_tracking_of_current_characters_on_stage: nil
  )
    tracking = global_tracking_of_current_characters_on_stage || @current_characters_on_stage
  puts "503 #{characters.size}"
    if stage_direction.attr('type') == 'entrance'
      tracking << characters
    elsif stage_direction.attr('type') == 'exit'
      all_characters = characters.concat(character_groups)
      all_characters.flatten!(2)
      all_characters.uniq!
      all_characters.each {|char| tracking.delete(char)}
    else
      puts "can't determine type of stage direction"
    end
    tracking.uniq!
    build_on_stages(french_scene: french_scene, characters: tracking)
    return tracking
  end

  def verify_no_more_children(item)
    if item.children.select(&:element?).size == 0
      return true
    else
      return false
    end
  end
end
