require 'rails_helper'

# Test suite for the Play model
RSpec.describe Play, type: :model do
  it "has a valid factory" do
    expect(build(:play)).to be_valid
  end

  let(:play) { create(:play, :with_full_structure) }

  describe "ActiveModel validations" do
    it { expect(play).to validate_presence_of(:title)}
  end

  describe "ActiveRecord associations" do
    it { expect(play).to belong_to(:author) }
    it { expect(play).to belong_to(:production).optional }
    it { expect(play).to have_many(:words).dependent(:delete_all) }
    it { expect(play).to have_many(:lines).through(:french_scenes) }
    it { expect(play).to have_many(:french_scenes).through(:scenes) }
    it { expect(play).to have_many(:scenes).through(:acts) }
    it { expect(play).to have_many(:acts).dependent(:destroy) }
    it { expect(play).to have_many(:characters).dependent(:destroy) }
    it { expect(play).to have_many(:character_groups).dependent(:destroy) }
    it { expect(play).to have_many(:on_stages).through(:french_scenes) }
  end
  it "serializes genre" do

  end
  it "finds onstages for play (but only one per character or group)" do
    on_stages = {
      character_ids: [play.characters.first.id, play.characters[1].id, play.characters.last.id],
      character_group_ids: [play.character_groups.first.id, play.character_groups.last.id]
    }
    create(:on_stage, french_scene: play.french_scenes.first, character: play.characters.first)
    create(:on_stage, french_scene: play.french_scenes.first, character: play.characters[1])
    create(:on_stage, french_scene: play.french_scenes.first, character_group: play.character_groups.first, character: nil)
    create(:on_stage, french_scene: play.french_scenes[4], character: play.characters.first)
    create(:on_stage, french_scene: play.french_scenes[4], character_group: play.character_groups.last, character: nil)
    create(:on_stage, french_scene: play.french_scenes.last, character: play.characters.first)
    create(:on_stage, french_scene: play.french_scenes.last, character: play.characters[1])
    create(:on_stage, french_scene: play.french_scenes.last, character: play.characters.last)
    create(:on_stage, french_scene: play.french_scenes.last, character_group: play.character_groups.last, character: nil)
    expect(play.find_on_stages.map(&:character_id).compact).to match_array(on_stages[:character_ids])
    expect(play.find_on_stages.map(&:character_group_id).compact).to match_array(on_stages[:character_group_ids])
  end
end
