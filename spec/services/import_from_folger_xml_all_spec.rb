require 'rails_helper'
RSpec.describe ImportFromFolgerXmlAll, type: :service do
  before(:each) do
    @import = ImportFromFolgerXmlAll.new('spec/data/folger_test.xml')
    create(:author, last_name: 'Shakespeare')
    @xml = @import.parsed_xml
    @play = @import.build_play(global_parsed_xml: @xml)
    # build_word (reached indirectly via build_scene/process_item/determine_type_of_item)
    # falls back to this instance's own `play` accessor when it isn't passed one
    # explicitly, so every example needs it set the same way 'builds acts' used to
    # set it as a side effect — that only worked before because before(:all) shared
    # one @import instance and relied on example run order.
    @import.play = @play
    create(:character_group, xml_id: "LORDS_AYL", play: @play)
    create(:character_group, xml_id: "ATTENDANTS_AYL", play: @play)
    lords_senior = create(:character_group, xml_id: "LORDS.SENIOR_AYL", play: @play)
    lords_fred = create(:character_group, xml_id: "LORDS.FREDERICK_AYL", play: @play)
    create(:character, xml_id: "Adam_AYL", name: "Adam", play: @play)
    create(:character, xml_id: "Orlando_AYL", name: "Orlando", play: @play)
    create(:character, xml_id: "Oliver_AYL", name: "Oliver", play: @play)
    create(:character, xml_id: "Rosalind_AYL", name: "Rosalind", play: @play)
    create(:character, xml_id: "Celia_AYL", name: "Celia", play: @play)
    create(:character, xml_id: "DukeFrederick_AYL", name: "Duke Frederick", play: @play)
    create(:character, xml_id: "Charles_AYL", name: "Charles", play: @play)
    create(:character, xml_id: "DukeSenior_AYL", name: "Duke Senior", play: @play)
    create(:character, xml_id: "LORDS.FREDERICK.0.1_AYL", character_group: lords_fred, play: @play)
    create(:character, xml_id: "LORDS.FREDERICK.0.2_AYL", character_group: lords_fred, play: @play)
    create(:character, xml_id: "LORDS.SENIOR.Amiens_AYL", character_group: lords_senior, play: @play)
    create(:character, xml_id: "CouldNotFindCharacter", character_group: lords_senior, play: @play)
    @characters = @play.characters
    @character_groups = @play.character_groups
  end

  it 'parses the xml' do
    expect(@xml.children.size).to be > 0
  end

  it 'builds a play' do
    play = @import.build_play(global_parsed_xml: @xml)
    expect(play.synopsis).to include('witty words and romance play out against the disputes of divided pairs')
    expect(play.title).to eq('As You Like It')
    expect(play.author).to eq(Author.find_by(last_name: 'Shakespeare'))
    expect(play.text_notes).to eq('Adapted from the Folger Digital Texts, edited by Barbara A. Mowat, Paul Werstine')
    expect(play.canonical).to be true
  end

  it 'builds a character group' do
    character_group = @xml.xpath('//personGrp')[2]
    character_groups = []
    character_group_imported = @import.build_character_group(
      character_group: character_group,
      play: @play,
      global_tracking_of_play_character_groups: character_groups
    )
    expect(character_group_imported.xml_id).to eq('LORDS.FREDERICK_AYL')
    expect(character_group_imported.corresp).to eq('#LORDS_AYL')
    expect(character_groups.size).to eq(1)
    expect(character_group_imported.play.id).to eq(@play.id)
  end

  it 'builds a character' do
    character = @xml.xpath('//person').first
    character_groups = []
    characters = []
    test_character = @import.build_character(
      character: character,
      play: @play,
      global_tracking_of_play_character_groups: character_groups,
      global_tracking_of_play_characters: characters
    )
    expect(test_character.play).to eq(@play)
    expect(test_character.description).to include('Old guy')
    expect(test_character.gender).to eq('male')
    expect(test_character.name).to eq('Adam')
    expect(test_character.xml_id).to eq('Adam_AYL')
    expect(characters).to include(test_character)
  end

  it 'builds a character and adds it to a character group' do
    character_group = @xml.xpath('//personGrp')[2]
    character_groups = []
    characters = []
    test_character_group = @import.build_character_group(
      character_group: character_group,
      play: @play,
      global_tracking_of_play_character_groups: character_groups
    )
    character = @xml.at_xpath('//person[@xml:id="LORDS.FREDERICK.0.2_AYL"]')
    test_character = @import.build_character(
      character: character,
      play: @play,
      global_tracking_of_play_character_groups: character_groups,
      global_tracking_of_play_characters: characters
    )
    expect(test_character.play).to eq(@play)
    expect(test_character.gender).to eq('male')
    expect(test_character.name).to eq('Second Lord')
    expect(test_character.xml_id).to eq('LORDS.FREDERICK.0.2_AYL')
    expect(test_character.corresp).to eq('#LORDS.FREDERICK_AYL')
    expect(test_character.character_group.xml_id).to eq('LORDS.FREDERICK_AYL')
  end

  it 'builds all the characters for the play' do
    characters = []
    character_groups = []
    @import.build_characters(
      play: @play,
      global_parsed_xml: @xml,
      global_tracking_of_play_characters: characters,
      global_tracking_of_play_character_groups: character_groups
    )
    expect(characters.map(&:xml_id)).to include('Rosalind_AYL')
    expect(character_groups.map(&:xml_id)).to include('LORDS_AYL')
  end

  it 'extracts characters from xml string' do
    characters = []
    character_groups = []
    @import.build_characters(
      play: @play,
      global_parsed_xml: @xml,
      global_tracking_of_play_characters: characters,
      global_tracking_of_play_character_groups: character_groups
    )
    xml_ids = '#Adam_AYL #DukeFrederick_AYL #LORDS.FREDERICK_AYL #fakecharacter!'
    character_parser = @import.extract_characters_from_xml_id_string(
      xml_ids: xml_ids,
      global_tracking_of_play_characters: characters,
      global_tracking_of_play_character_groups: character_groups
    )
    expect(character_parser.size).to eq(2)
    expect(character_parser[0].size).to eq(3)
    expect(character_parser[0][0].name).to eq('Adam')
    expect(character_parser[1].size).to eq(1)
    expect(character_parser[1][0].xml_id).to eq('LORDS.FREDERICK_AYL')
    expect(character_parser[0][2].xml_id).to eq('CouldNotFindCharacter')
  end

  it 'builds onstages' do
    french_scene = create(:french_scene)
    characters = [@characters, @character_groups]
    character_count = @characters.size + @character_groups.size
    old_on_stages = @play.on_stages.size
    on_stages = []
    new_on_stages = @import.build_on_stages(
      french_scene: french_scene,
      characters: characters,
      global_tracking_of_on_stages: on_stages
    )
    expect(character_count + old_on_stages).to eq(new_on_stages.size)
  end

  it 'tracks who is onstage' do
    all_play_characters = @import.build_characters(
      play: @play,
      global_parsed_xml: @xml
    )
    french_scene = create(:french_scene)
    stage_direction = @xml.at_xpath('//stage[@xml:id="stg-0170.2"]')
    character_xml_ids = stage_direction.attr('who').gsub("#", "").split(' ')
    characters = []
    character_xml_ids.each do |xml|
      characters << all_play_characters.find { |character| character.xml_id == xml }
    end
    current_characters_onstage = []
    characters_onstage = @import.track_onstage_characters(
      french_scene: french_scene,
      stage_direction: stage_direction,
      characters: characters,
      global_tracking_of_current_characters_on_stage: current_characters_onstage
    )
    expect(characters_onstage.size).to eq(2)
    expect(characters_onstage.first.xml_id).to eq('Rosalind_AYL')
    stage_direction = @xml.at_xpath('//stage[@xml:id="stg-2862.1"]')
    character_xml_ids = stage_direction.attr('who').gsub("#", "").split(' ')
    characters = []
    character_xml_ids.each do |xml|
      characters << all_play_characters.find { |character| character.xml_id == xml }
    end
    characters_onstage = @import.track_onstage_characters(
      french_scene: french_scene,
      stage_direction: stage_direction,
      characters: characters,
      global_tracking_of_current_characters_on_stage: current_characters_onstage
    )
    expect(characters_onstage.size).to eq(1)
  end

  it 'builds acts' do
    act = @import.build_acts(
      play: @play,
      parsed_xml: @xml,
      global_tracking_of_play_characters: @characters,
      global_tracking_of_play_character_groups: @character_groups
    )
    expect(act.number).to eq(6)
    expect(act.heading).to eq('EPILOGUE')
  end

  it 'builds a french scene' do
    scene = build(:scene)
    test_french_scene = @import.build_french_scene(french_scene_number: 'b', scene: scene, play: @play)
    expect(test_french_scene.number).to eq('b')
    expect(test_french_scene.scene).to eq(scene)
  end

  it 'builds a scene' do
    all_play_characters = @import.build_characters(
      play: @play,
      global_parsed_xml: @xml
    )

    act = build(:act)
    scene = @xml.xpath('//div2')[1]
    test_scene = @import.build_scene(act: act, scene: scene, play: @play, global_tracking_of_play_characters: @characters, global_tracking_of_play_character_groups: @character_groups)
    expect(test_scene.act_id).to eq(act.id)
    expect(test_scene.heading).to eq('Scene 2')
    expect(test_scene.french_scenes.size).to eq(3)
  end

  it 'builds a header' do
    head_text = @xml.xpath('//div2/head').first
    expect(@import.build_header(item: head_text)).to eq('Scene 1')
  end

  it 'builds a line' do
    character = create(:character)
    french_scene = create(:french_scene)
    line = @xml.at_xpath('//milestone[@xml:id="ftln-0172"]')
    test_line = @import.build_line(character: [character], french_scene: french_scene, line: line)
    expect(test_line.character).to eq(character)
    expect(test_line.french_scene).to eq(french_scene)
  end

  it 'builds a line of content' do #too deep in the weeds to legitimately unit test, I think...
    character = create(:character)
    french_scene = create(:french_scene)
    line = @xml.at_xpath('//milestone[@xml:id="ftln-0172"]')
    test_line = @import.build_line(character: [character], french_scene: french_scene, line: line)
    @import.build_lines_content([test_line]).each {|l| puts line.content}
  end

  it 'builds a sound cue' do
    french_scene = create(:french_scene)
    item = @xml.at_xpath('//sound[@xml:id="snd-0312.1"]')
    sound_cue = @import.build_sound_cue(french_scene: french_scene, item: item)
    expect(sound_cue.original_content).to eq('Flourish.')
    expect(sound_cue.french_scene).to eq(french_scene)
    expect(sound_cue.line_number).to eq('SD 1.2.142.1')
    expect(sound_cue.notes).to eq('flourish')
    expect(sound_cue.kind).to eq('flourish')
    expect(sound_cue.xml_id).to eq('snd-0312.1')
  end

  # it 'builds a speech' do

  # end

  it 'builds a stage direction' do
    french_scene = create(:french_scene)
    line = @xml.at_xpath('//stage[@xml:id="stg-0312.1"]')
    test_stage_direction = @import.build_stage_direction(
      global_tracking_of_current_french_scene: french_scene,
      item: line,
      global_tracking_of_play_characters: @characters,
      global_tracking_of_play_character_groups: @character_groups
    )
    expect(test_stage_direction.original_content).to eq(' Enter Duke Frederick, Lords, Orlando,Charles, and Attendants.')
    expect(test_stage_direction.french_scene).to eq(french_scene)
    expect(test_stage_direction.number).to eq('SD 1.2.142.1')
    expect(test_stage_direction.kind).to eq('entrance')
    expect(test_stage_direction.xml_id).to eq('stg-0312.1')
    expect(test_stage_direction.characters.first.xml_id).to eq('DukeFrederick_AYL')
    test_stage_direction.characters.each {|c| puts "#{c.name}\t#{c.xml_id}"}
    expect(test_stage_direction.characters.size).to eq(3)
    expect(test_stage_direction.character_groups.size).to eq(2)
  end

  it 'builds a word' do
    line = build(:line)
    word = @xml.at_xpath('//w[@xml:id="w0153740"]')
    space = @xml.at_xpath('//c[@xml:id="c0153750"]')
    punctuation = @xml.at_xpath('//pc[@xml:id="p0153790"]')
    test_word = @import.build_word(word: word, play: @play)
    test_space = @import.build_word(word: space, play: @play)
    test_punctuation = @import.build_word(word: punctuation, play: @play)
    expect(test_word.kind).to eq('word')
    expect(test_word.content).to eq("What’s")
    expect(test_word.line_number).to eq('2.5.56')
    expect(test_space.kind).to eq('space')
    expect(test_space.content).to eq(" ")
    expect(test_space.line_number).to eq('2.5.56')
    expect(test_punctuation.kind).to eq('punctuation')
    expect(test_punctuation.content).to eq("?")
    expect(test_punctuation.line_number).to eq('2.5.56')
  end

  it 'connects lines to words' do
    act = create(:act, play: @play)
    scene = create(:scene, act: act)
    french_scene = create(:french_scene, scene: scene)
    french_scene.lines << create(:line, corresp: "#w0000700 #c0000710 #w0000720 #c0000730 #w0000740 #c0000750 #w0000760 #c0000770 #w0000780 #c0000790 #w0000800 #p0000810 #c0000820 #w0000830 #c0000840 #w0000850 #c0000860 #w0000870 #c0000880 #w0000890")
    word01 = create(:word, xml_id: "w0000700")
    @play.words << word01
    @play.words << create(:word, xml_id: "c0000710")
    @play.words << create(:word, xml_id: "w0000720")
    @play.words << create(:word, xml_id: "c0000730")
    @play.words << create(:word, xml_id: "w0000740")
    @play.words << create(:word, xml_id: "c0000750")
    @play.words << create(:word, xml_id: "w0000760")
    @play.words << create(:word, xml_id: "c0000770")
    @play.words << create(:word, xml_id: "w0000780")
    @play.words << create(:word, xml_id: "c0000790")
    @play.words << create(:word, xml_id: "w0000800")
    @play.words << create(:word, xml_id: "p0000810")
    @play.words << create(:word, xml_id: "c0000820")
    @play.words << create(:word, xml_id: "w0000830")
    @play.words << create(:word, xml_id: "c0000840")
    @play.words << create(:word, xml_id: "w0000850")
    @play.words << create(:word, xml_id: "c0000860")
    @play.words << create(:word, xml_id: "w0000870")
    @play.words << create(:word, xml_id: "c0000880")
    word20 = create(:word, xml_id: "w0000890")
    @play.words << word20
    @import.connect_lines_to_words(play: @play)
    expect(@play.lines.first.words.size).to eq(20)
    expect(@play.lines.first.words.first).to eq(word01)
    expect(@play.lines.first.words.last).to eq(word20)
    expect(Word.find(word01.id).line_id).to eq(@play.lines.first.id)
    expect(Word.find(word20.id).line_id).to eq(@play.lines.first.id)
  end

  # it 'determines the type of item' do
  #   #tk
  # end

  it 'extracts content and builds a text string' do
    item = @xml.at_xpath('//sound[@xml:id="snd-0312.1"]')
    content = @import.extract_content(item: item)
    expect(content).to eq('Flourish.')
  end

  # it 'extracts items from corresp' do
  #   #tk
  # end
  # it 'processes an item' do

  # end
  it 'checks that item has no children' do
    no_children = @xml.at_xpath('//w[@xml:id="w0153740"]')
    expect(@import.verify_no_more_children(no_children)).to be true
    has_children = @xml.at_xpath('//q[@xml:id="q-0016"]')
    expect(@import.verify_no_more_children(has_children)).to be false
  end



  it "builds speeches and lines for a scene" do
    speeches = @xml.xpath('//sp')
    scene = @xml.xpath('//div1[@n="1"]/div2')[1]
    act = build(:act)
    test_scene = @import.build_scene(act: act, scene: scene, play: @play, global_tracking_of_play_characters: @characters, global_tracking_of_play_character_groups: @character_groups)
    expect(test_scene.french_scenes.size).to eq(3)
  end
end
