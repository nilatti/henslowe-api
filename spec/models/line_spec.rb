require 'rails_helper'

RSpec.describe Line, type: :model do
  # before(:each) do
  #   @play = create(:play, :with_full_structure, canonical: true) #this play has three acts. each act has 3 scenes. each scene has 3 french scenes.
  #   @first_act = @play.acts.first
  #   @first_scene = @first_act.scenes.first
  #   @character = create(:character, play: @play)
  #   @line = create(:line, french_scene: @first_scene.french_scenes.first, character: @character, original_content: 'If music be the food of love, play on!', new_content: '')
  # end

  let(:play) {create(:play, :with_full_structure, canonical: true)} #this play has three acts. each act has 3 scenes. each scene has 3 french scenes.
  let(:character) {play.characters.first}
  let(:act) {play.acts.first}
  let(:scene) {act.scenes.first}
  let(:french_scene) {scene.french_scenes.first}
  let(:line) { create(:line, french_scene: french_scene, character: character, original_content: 'If music be the food of love, play on!', new_content: '') }

  describe "ActiveRecord associations" do
    it { expect(line).to belong_to(:character).optional }
    it { expect(line).to belong_to(:character_group).optional }
    it { expect(line).to belong_to(:french_scene) }
    it { expect(line).to have_many(:words).dependent(:destroy) }
  end

  describe "it knows its parents" do
    it { expect(line.scene).to eq(scene)}
    it { expect(line.act).to eq(act)}
    it { expect(line.play).to eq(play)}
  end

  it 'computes original_line_count and new_line_count live from line content, cascading through character/play/act/scene/french_scene' do
    line # create the line, with original_content: 'If music be the food of love, play on!' (10 syllables = 1.0) and new_content: '' (cut, 0.0)

    [character, play, act, scene, french_scene].each do |countable|
      expect(countable.original_line_count).to eq(1.0)
      expect(countable.new_line_count).to eq(0.0)
    end
  end

  it 'falls back to original_content when new_content is nil (unedited)' do
    unedited_line = create(:line, french_scene: french_scene, character: character, original_content: 'If music be the food of love, play on!', new_content: nil)
    expect(unedited_line.play.new_line_count).to eq(unedited_line.play.original_line_count)
  end
end
