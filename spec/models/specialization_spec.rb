require 'rails_helper'

RSpec.describe Specialization, type: :model do
  it "has a valid factory" do
    expect(build(:specialization)).to be_valid
  end

  let(:specialization) { build(:specialization) }

  it { expect(specialization).to validate_presence_of(:title)}

  describe 'phase associations' do
    it { expect(build(:specialization)).to belong_to(:default_start_phase).class_name('Phase').optional }
    it { expect(build(:specialization)).to belong_to(:default_end_phase).class_name('Phase').optional }

    it 'accepts phase assignment' do
      phase = create(:phase)
      spec = create(:specialization, default_start_phase: phase, default_end_phase: phase)
      expect(spec.reload.default_start_phase_id).to eq(phase.id)
      expect(spec.reload.default_end_phase_id).to eq(phase.id)
    end
  end

  it "scopes function" do
    actor_specialization = create(:specialization, title: 'Actor')
    auditioner_specialization = create(:specialization, title: 'Auditioner')

    expect(Specialization.actor).to match_array([actor_specialization])
    expect(Specialization.auditioner).to match_array([auditioner_specialization])
    expect(Specialization.actor_or_auditioner).to match_array([actor_specialization].push(auditioner_specialization))
  end
end
