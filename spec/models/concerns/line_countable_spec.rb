require 'rails_helper'

RSpec.describe LineCountable do
  let(:play) { create(:play) }
  let(:character) { create(:character, play: play) }
  let(:french_scene) { create(:french_scene) }

  def line_for(character, original:, new_content:)
    create(:line, character: character, french_scene: french_scene, original_content: original, new_content: new_content)
  end

  describe '#original_line_count and #new_line_count' do
    it 'is 0.0 for a character with no lines' do
      expect(character.original_line_count).to eq(0.0)
      expect(character.new_line_count).to eq(0.0)
    end

    it 'weighs a line by syllables per ten-syllable line' do
      line_for(character, original: 'If music be the food of love, play on!', new_content: nil)
      expect(character.original_line_count).to eq(1.0)
      expect(character.new_line_count).to eq(1.0)
    end

    it 'uses new_content over original_content when the line was edited' do
      line_for(character, original: 'If music be the food of love, play on!', new_content: 'I will, my lord')
      expect(character.original_line_count).to eq(1.0)
      expect(character.new_line_count).to eq(0.4)
    end

    it 'counts a line cut to blank new_content as 0 toward new_line_count but not original_line_count' do
      line_for(character, original: 'If music be the food of love, play on!', new_content: '')
      expect(character.original_line_count).to eq(1.0)
      expect(character.new_line_count).to eq(0.0)
    end

    it 'sums across multiple lines' do
      line_for(character, original: 'If music be the food of love, play on!', new_content: nil)
      line_for(character, original: 'I will, my lord', new_content: nil)
      expect(character.original_line_count).to eq(1.4)
      expect(character.new_line_count).to eq(1.4)
    end
  end

  describe '#as_json' do
    it 'always includes original_line_count and new_line_count, regardless of caller options' do
      line_for(character, original: 'I will, my lord', new_content: nil)
      json = character.as_json(only: [:id, :name])
      expect(json['original_line_count']).to eq(0.4)
      expect(json['new_line_count']).to eq(0.4)
    end
  end
end
