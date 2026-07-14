require 'rails_helper'

RSpec.describe FrenchScene, type: :model do
  it "has a valid factory" do
    expect(build(:french_scene)).to be_valid
  end

  let(:french_scene) { build(:french_scene) }

  describe "ActiveModel validations" do
    it { expect(french_scene).to validate_presence_of(:number) }
  end

  describe "ActiveRecord associations" do
    it { expect(french_scene).to belong_to(:scene) }
    it { expect(french_scene).to have_many(:entrance_exits).dependent(:destroy) }
    it { expect(french_scene).to have_many(:lines).dependent(:delete_all) }
    it { expect(french_scene).to have_many(:on_stages).dependent(:delete_all) }
    it { expect(french_scene).to have_many(:sound_cues).dependent(:delete_all) }
    it { expect(french_scene).to have_many(:stage_directions).dependent(:destroy) }
    it { expect(french_scene).to have_many(:characters).through(:on_stages) }
    it { expect(french_scene).to have_many(:character_groups).through(:on_stages) }
    it { expect(french_scene).to have_many(:users).through(:on_stages) }
    it { expect(french_scene).to have_and_belong_to_many(:rehearsals) }
  end

 it "it default scope orders by number" do
    french_scene1 = create(:french_scene, number: "c")
    french_scene2 = create(:french_scene, number: "a")
    expect(FrenchScene.all.first.number).to eq("a")
  end

  it "has a pretty name" do
    act = build(:act)
    scene = build(:scene, act: act)
    french_scene = build(:french_scene, scene: scene)
    expect(french_scene.pretty_name).to eq("#{'%02d' % act.number}.#{'%02d' % scene.number}.#{french_scene.number}")
  end
  it "sorts in play order" do
    play = build(:play)
    act1 = build(:act, number: 1, play: play)
    act2 = build(:act, number: 2, play: play)
    scene3 = build(:scene, number: 1, act: act2)
    scene2 = build(:scene, number: 2, act: act1)
    scene1 = build(:scene, number: 1, act: act1)

    french_scene1 = build(:french_scene, number: "a", scene: scene1)
    french_scene5 = build(:french_scene, number: "b", scene: scene3)
    french_scene3 = build(:french_scene, number: "c", scene: scene2)
    french_scene2 = build(:french_scene, number: "b", scene: scene1)
    french_scene4 = build(:french_scene, number: "a", scene: scene2)
    french_scenes = [french_scene1, french_scene2, french_scene3, french_scene4, french_scene5]
    expect(FrenchScene.play_order(french_scenes).first).to be(french_scene1)
    expect(FrenchScene.play_order(french_scenes).last).to be(french_scene5)
  end

  it 'does not build a new record if all aspects of on_stage is nil' do
    french_scene = create(:french_scene)
    french_scene.on_stages_attributes = [{
      character_id: nil,
      french_scene_id: nil,
    }]
    french_scene.save!

    expect(french_scene.on_stages.count).to eq 0
  end

  it 'does not build a new record if one aspect of on_stage is nil' do
    french_scene = create(:french_scene)
    french_scene.on_stages_attributes = [{
      character_id: nil,
      french_scene_id: french_scene.id,
    }]
    french_scene.valid?
    expect(french_scene.errors[:"on_stages.on_stage"]).to include("Must have character or character group")
  end
  it "does build new record if on_stage is valid" do
    french_scene = create(:french_scene)
    character = create(:character)
    french_scene.on_stages_attributes = [{
      character_id: character.id,
      french_scene_id: french_scene.id,
    }]
    french_scene.valid?
    expect(french_scene).to be_valid
  end
end
