require 'rails_helper'

RSpec.describe Phase, type: :model do
  it 'has a valid factory' do
    expect(build(:phase)).to be_valid
  end

  let(:phase) { build(:phase) }

  describe 'validations' do
    it { expect(phase).to validate_presence_of(:name) }

    it 'requires a unique name' do
      create(:phase, name: 'Rehearsals')
      duplicate = build(:phase, name: 'Rehearsals')
      expect(duplicate).not_to be_valid
    end
  end

  describe 'associations' do
    it { expect(phase).to have_many(:production_phases).dependent(:destroy) }
    it { expect(phase).to have_many(:specializations_with_start) }
    it { expect(phase).to have_many(:specializations_with_end) }
  end

  describe 'default scope' do
    it 'orders by position then name' do
      phase_c = create(:phase, name: 'Zebra', position: 2)
      phase_a = create(:phase, name: 'Alpha', position: 1)
      phase_b = create(:phase, name: 'Middle', position: nil)

      ordered = Phase.all.to_a
      expect(ordered.index(phase_a)).to be < ordered.index(phase_c)
      # nil position sorts after numbered positions
      expect(ordered.last).to eq(phase_b)
    end
  end

  describe 'nullifying specialization phase references on destroy' do
    it 'nullifies default_start_phase_id on associated specializations' do
      phase = create(:phase)
      specialization = create(:specialization, default_start_phase: phase)
      phase.destroy
      expect(specialization.reload.default_start_phase_id).to be_nil
    end

    it 'nullifies default_end_phase_id on associated specializations' do
      phase = create(:phase)
      specialization = create(:specialization, default_end_phase: phase)
      phase.destroy
      expect(specialization.reload.default_end_phase_id).to be_nil
    end
  end
end
