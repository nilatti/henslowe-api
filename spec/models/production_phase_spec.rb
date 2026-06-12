require 'rails_helper'

RSpec.describe ProductionPhase, type: :model do
  it 'has a valid factory' do
    expect(build(:production_phase)).to be_valid
  end

  describe 'associations' do
    let(:pp) { build(:production_phase) }
    it { expect(pp).to belong_to(:production) }
    it { expect(pp).to belong_to(:phase) }
  end

  describe 'uniqueness' do
    it 'prevents duplicate phase on the same production' do
      existing = create(:production_phase)
      duplicate = build(:production_phase, production: existing.production, phase: existing.phase)
      expect(duplicate).not_to be_valid
    end

    it 'allows the same phase on different productions' do
      phase = create(:phase)
      create(:production_phase, phase: phase)
      second = build(:production_phase, phase: phase)
      expect(second).to be_valid
    end
  end
end
