require 'rails_helper'

RSpec.describe Song, type: :model do
  it "has a valid factory" do
    expect(build(:song)).to be_valid
  end

  let(:song) { build(:song) }

  describe "ActiveModel validations" do
    it "is invalid without a title" do
      song_without_title = build(:song, title: nil)
      song_without_title.valid?
      expect(song_without_title.errors[:title]).to include("can't be blank")
    end

    it "is invalid without a french_scene" do
      song_without_scene = build(:song, french_scene: nil)
      expect(song_without_scene).not_to be_valid
    end
  end

  describe "ActiveRecord associations" do
    it { expect(song).to belong_to(:french_scene) }
    it { expect(song).to have_and_belong_to_many(:characters) }
  end

  describe "characters association" do
    it "can have multiple characters" do
      song = create(:song)
      characters = create_list(:character, 2)
      song.characters << characters
      expect(song.characters.count).to eq(2)
    end
  end
end
