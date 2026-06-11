require 'rails_helper'

RSpec.describe OnStage, type: :model do
  it "has a valid factory" do
    expect(build(:on_stage)).to be_valid
  end

  let(:on_stage) { build(:on_stage) }

  describe "ActiveModel validations" do
    it "checks that start date is before end date" do
      on_stage_wo_french_scene = build(:on_stage, french_scene: nil)
      on_stage_wo_french_scene.valid?
      expect(on_stage_wo_french_scene.errors[:on_stage]).to include("Must have french scene")
      on_stage_wo_characters = build(:on_stage, character: nil, character_group: nil)
      on_stage_wo_characters.valid?
      expect(on_stage_wo_characters.errors[:on_stage]).to include("Must have character or character group")
      on_stage.valid?
      expect(on_stage).to be_valid
    end
    it "detects if category is unset" do
      on_stage_wo_category_w_character = build(:on_stage, category: nil, character: build(:character))
      expect(on_stage_wo_category_w_character.send(:category_unset?)).to be_truthy

      on_stage_wo_category_w_character = build(:on_stage, category: 'Character', character: build(:character))
      expect(on_stage_wo_category_w_character.send(:category_unset?)).to be_falsey
    end
    it "sets category if unset" do
      on_stage_wo_category_w_character = build(:on_stage, category: nil, character: build(:character))
      on_stage_wo_category_w_character.save
      expect(on_stage_wo_category_w_character.category).to eq('Character')
      on_stage_wo_category_wo_character = build(:on_stage, category: nil, character: nil, character_group: build(:character_group))
      on_stage_wo_category_wo_character.save
      expect(on_stage_wo_category_wo_character.category).to eq('Other')
      on_stage_w_category = build(:on_stage, category: 'Test Category')
      on_stage_wo_category_w_character.save
      expect(on_stage_w_category.category).to eq('Test Category')
    end
  end

  describe "ActiveRecord associations" do
    it { expect(on_stage).to belong_to(:character).optional }
    it { expect(on_stage).to belong_to(:character_group).optional }
    it { expect(on_stage).to belong_to(:user).optional }
    it { expect(on_stage).to belong_to(:french_scene).optional }
  end

  describe "offstage attribute" do
    it "defaults to false" do
      saved = create(:on_stage)
      expect(saved.offstage).to be false
    end

    it "can be set to true" do
      saved = create(:on_stage, offstage: true)
      expect(saved.offstage).to be true
    end
  end
end
