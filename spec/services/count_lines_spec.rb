require 'rails_helper'

describe CountLines do
  before(:all) do
    @play = create(:play, :with_full_structure, canonical: true) #this play has three acts. each act has 3 scenes. each scene has 3 french scenes.
    first_act = @play.acts.first
    @first_scene = first_act.scenes.first
    @character1 = create(:character, play: @play)
    @character2 = create(:character, play: @play)
    @character3 = create(:character, play: @play)
    @on_stage1 = create(:on_stage, french_scene: @first_scene.french_scenes.first, character: @character1)
    @on_stage2 = create(:on_stage, french_scene: @first_scene.french_scenes.first, character: @character2)
    @on_stage3 = create(:on_stage, french_scene: @first_scene.french_scenes.first, character: @character3)
    line1 = create(:line, french_scene: @first_scene.french_scenes.first, character: @character1, original_content: 'If music be the food of love, play on!', new_content: 'If music be the food of love, yum yum yum yum yum!')
    line2 = create(:line, french_scene: @first_scene.french_scenes.first, character: @character2, original_content: 'I dreamed there was an emperor, Antony', new_content: 'I dreamed there was a god, Antony')
    line3 = create(:line, french_scene: @first_scene.french_scenes.first, character: @character2, original_content: 'Speak the speech, I pray you, as I pronounced it to you', new_content: nil)
    @counter = CountLines.new(lines: [line1, line2, line3], play: @play)
  end

  it 'gets characters' do
    characters = @counter.get_characters(lines: @counter.lines)
    expect(characters.first).to be(@character1)
  end

  it 'gets line lengths' do
    updated_lines = @counter.get_line_lengths(lines: @counter.lines)
    expect(updated_lines.size).to eq(3)
    expect(updated_lines[0][:original_line_count]).to eq(1.0)
    expect(updated_lines[2][:original_line_count]).to eq(1.3)
    expect(updated_lines[2][:new_line_count]).to eq(1.3)
    expect(updated_lines[1][:new_line_count]).to eq(0.9)
  end

  it 'runs the program' do
    @counter.run
    expect(@counter.updated_lines[0][:original_line_count]).to eq(1.0)
    expect(@counter.updated_lines[2][:original_line_count]).to eq(1.3)
    expect(@counter.updated_lines[2][:new_line_count]).to eq(1.3)
    expect(@counter.updated_lines[1][:new_line_count]).to eq(0.9)
    expect (@character1.original_line_count == 10)
    expect (@character1.new_line_count == 1.2)
    expect (@character2.original_line_count == 24)
    expect (@play.original_line_count == 3.4)
    expect (@play.new_line_count == 2.2)
  end

  it 'updates character line counts' do
    updated_lines = @counter.get_line_lengths(lines: @counter.lines)
    @counter.import_line_counts(updated_lines: updated_lines)
    @counter.update_characters(characters: [@character1, @character2])
    expect (@character1.original_line_count == 10)
    expect (@character1.new_line_count == 1.2)
    expect (@character2.original_line_count == 24)
  end

  it 'updates onstages speaking or not' do
    @counter.update_on_stage_nonspeaking(on_stages: @first_scene.french_scenes.first.on_stages)
    on_stage3 = OnStage.find(@on_stage3.id)
    on_stage2 = OnStage.find(@on_stage2.id)
    expect(on_stage3.nonspeaking).to be true
    expect(on_stage2.nonspeaking).to be false
  end

  it 'updates play line counts' do
    updated_lines = @counter.get_line_lengths(lines: @counter.lines)
    @counter.import_line_counts(updated_lines: updated_lines)
    @counter.update_play(play: @play)
    expect (@play.original_line_count == 3.4)
    expect (@play.new_line_count == 2.2)
  end
end

# next, make it update lines, play, and characters at every line save.
# then, return only line counts, not actual lines, most of the time
