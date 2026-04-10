require 'rails_helper'

RSpec.describe Act, type: :model do
  it "has a valid factory" do
    # Using the shortened version of FactoryGirl syntax.
    # Add:  "config.include FactoryGirl::Syntax::Methods" (no quotes) to your spec_helper.rb
    expect(build(:act)).to be_valid
  end
  let(:play) { create(:play, :with_full_structure) }
  let(:act) { create(:act, :with_scenes, play: play) }

  describe "ActiveModel validations" do
    # http://guides.rubyonrails.org/active_record_validations.html
    # http://rubydoc.info/github/thoughtbot/shoulda-matchers/master/frames
    # http://rubydoc.info/github/thoughtbot/shoulda-matchers/master/Shoulda/Matchers/ActiveModel

    # Basic validations
    it { expect(act).to validate_presence_of(:number) }

    # Format validations
    # Inclusion/acceptance of values
  end

  describe "ActiveRecord associations" do
      it { expect(act).to have_many(:scenes) }
      it { expect(act).to belong_to(:play) }
  end

  it "finds onstages for play (but only one per character or group)" do
    characters = play.characters.reload
    character_groups = play.character_groups.reload
    on_stages = {
      character_ids: [characters.first.id, characters[1].id, characters.last.id],
      character_group_ids: [character_groups.first.id, character_groups.last.id]
    }
    create(:on_stage, french_scene: act.french_scenes.first, character: characters.first)
    create(:on_stage, french_scene: act.french_scenes.first, character: characters[1])
    create(:on_stage, french_scene: act.french_scenes.first, character_group: character_groups.first, character: nil)
    create(:on_stage, french_scene: act.french_scenes[4], character: characters.first)
    create(:on_stage, french_scene: act.french_scenes[4], character_group: character_groups.last, character: nil)
    create(:on_stage, french_scene: act.french_scenes.last, character: characters.first)
    create(:on_stage, french_scene: act.french_scenes.last, character: characters[1])
    create(:on_stage, french_scene: act.french_scenes.last, character: characters.last)
    create(:on_stage, french_scene: act.french_scenes.last, character_group: character_groups.last, character: nil)
    expect(play.find_on_stages.map(&:character_id).compact).to match_array(on_stages[:character_ids])
    expect(play.find_on_stages.map(&:character_group_id).compact).to match_array(on_stages[:character_group_ids])
  end
end
