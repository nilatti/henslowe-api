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

  it 'updates own line count, character line count, and play line count on save' do
    # not sure why this works, as Sidekiq theoretically doesn't call in test...
    line.new_content = 'If music be the banquet of love, perform it continually.'
    line.save
    expect { UpdateLineCountWorker.perform_async(line.id) }.to change { UpdateLineCountWorker.jobs.size }.by(1)
    expect(line.new_content).to eq('If music be the banquet of love, perform it continually.')
    expect(line.original_line_count == 1.0)
    expect(line.new_line_count == 1.8)
    expect(character.original_line_count == 1.0)
    expect(character.new_line_count == 1.8)
    expect(play.original_line_count == 1.0)
    expect(play.new_line_count == 1.8)
    expect(act.original_line_count == 1.0)
    expect(act.new_line_count == 1.8)
    expect(scene.original_line_count == 1.0)
    expect(scene.new_line_count == 1.8)
    expect(french_scene.original_line_count == 1.0)
    expect(french_scene.new_line_count == 1.8)
  end
end
