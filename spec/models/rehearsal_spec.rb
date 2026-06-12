require 'rails_helper'

RSpec.describe Rehearsal, type: :model do
  it "has a valid factory" do
    expect(build(:rehearsal)).to be_valid
  end

  let(:rehearsal) { build(:rehearsal) }

  describe "ActiveRecord associations" do
    it { expect(rehearsal).to belong_to(:space).optional }
    it { expect(rehearsal).to belong_to(:production) }
    it { expect(rehearsal).to have_and_belong_to_many(:acts) }
    it { expect(rehearsal).to have_and_belong_to_many(:scenes) }
    it { expect(rehearsal).to have_and_belong_to_many(:french_scenes) }
    it { expect(rehearsal).to have_and_belong_to_many(:users) }
    it { expect(rehearsal).to have_many(:conflicts).dependent(:destroy) }
  end

  describe '#sync_conflicts' do
    let(:rehearsal) { create(:rehearsal) }
    let(:user) { create(:user) }

    before { rehearsal.users << user }

    it 'creates a space conflict for the rehearsal space' do
      rehearsal.sync_conflicts
      expect(rehearsal.conflicts.where(space: rehearsal.space, user: nil).count).to eq(1)
    end

    it 'creates a user conflict for each called user' do
      rehearsal.sync_conflicts
      expect(rehearsal.conflicts.where(user: user, space: nil).count).to eq(1)
    end

    it 'sets category to rehearsal on all conflicts' do
      rehearsal.sync_conflicts
      expect(rehearsal.conflicts.pluck(:category).uniq).to eq(['rehearsal'])
    end

    it 'is idempotent' do
      rehearsal.sync_conflicts
      rehearsal.sync_conflicts
      expect(rehearsal.conflicts.count).to eq(2)
    end

    it 'removes the space conflict when space is cleared' do
      rehearsal.sync_conflicts
      rehearsal.update!(space: nil)
      rehearsal.sync_conflicts
      expect(rehearsal.conflicts.where(user_id: nil).count).to eq(0)
    end

    it 'removes the user conflict when the user is removed' do
      rehearsal.sync_conflicts
      rehearsal.users.delete(user)
      rehearsal.sync_conflicts
      expect(rehearsal.conflicts.where(user: user).count).to eq(0)
    end

    it 'does nothing when start_time is absent' do
      rehearsal.update_column(:start_time, nil)
      rehearsal.sync_conflicts
      expect(rehearsal.conflicts.count).to eq(0)
    end
  end

end
