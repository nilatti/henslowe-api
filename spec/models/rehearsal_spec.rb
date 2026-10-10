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

  describe '#calendar_description' do
    let(:rehearsal) { create(:rehearsal, notes: 'Bring scripts') }
    let(:act) { create(:act, heading: 'The Beginning', start_page: 5, end_page: 12) }

    def call(first_name, last_name, preferred_name: nil, **attrs)
      create(:user, first_name: first_name, last_name: last_name, preferred_name: preferred_name, **attrs).tap do |u|
        rehearsal.users << u
      end
    end

    it 'lists content, then the call list, then notes' do
      rehearsal.acts << act
      call('Ann', 'Smith')
      expect(rehearsal.calendar_description).to eq("The Beginning (pp. 5–12)\nCalled: Ann Smith\nBring scripts")
    end

    it 'alphabetizes the call list by last name, then first name' do
      call('Zoe', 'Young')
      call('Bea', 'Adams')
      call('Al', 'Adams')
      call('Max', 'miller') # lowercase sorts alongside its letter, not after Z
      expect(rehearsal.call_list_content).to eq('Called: Al Adams, Bea Adams, Max miller, Zoe Young')
    end

    it 'uses preferred names when set' do
      call('Robert', 'Adams', preferred_name: 'Bob')
      expect(rehearsal.call_list_content).to eq('Called: Bob Adams')
    end

    it 'includes placeholder actors and staff alike' do
      call('Stage', 'Manager')
      call('Fake', 'Actor', fake: true, provider: 'fake')
      expect(rehearsal.call_list_content).to eq('Called: Fake Actor, Stage Manager')
    end

    it 'omits the call list when no one is called' do
      expect(rehearsal.calendar_description).to eq('Bring scripts')
    end
  end

  describe 'text unit order' do
    let(:play) { create(:play) }
    let(:act1) { create(:act, play: play, number: 1, heading: 'Act One') }
    let(:act2) { create(:act, play: play, number: 2, heading: 'Act Two') }
    let(:scene_1_2) { create(:scene, act: act1, number: 2) }
    let(:scene_2_1) { create(:scene, act: act2, number: 1) }
    let(:fs_1_2_b) { create(:french_scene, scene: scene_1_2, number: 'b') }
    let(:fs_2_1_a) { create(:french_scene, scene: scene_2_1, number: 'a') }
    let(:fs_1_2_a) { create(:french_scene, scene: scene_1_2, number: 'a') }
    let(:rehearsal) { create(:rehearsal) }

    it 'returns acts in play order' do
      rehearsal.acts << act2 << act1
      expect(rehearsal.reload.acts).to eq([act1, act2])
    end

    it 'returns scenes in play order, not by scene number alone' do
      rehearsal.scenes << scene_2_1 << scene_1_2
      expect(rehearsal.reload.scenes).to eq([scene_1_2, scene_2_1])
    end

    it 'returns french scenes in play order, not by french scene number alone' do
      rehearsal.french_scenes << fs_2_1_a << fs_1_2_b << fs_1_2_a
      expect(rehearsal.reload.french_scenes).to eq([fs_1_2_a, fs_1_2_b, fs_2_1_a])
    end

    it 'keeps play order when preloaded' do
      rehearsal.scenes << scene_2_1 << scene_1_2
      rehearsal.french_scenes << fs_2_1_a << fs_1_2_a
      preloaded = Rehearsal.includes(:scenes, :french_scenes).find(rehearsal.id)
      expect(preloaded.scenes).to eq([scene_1_2, scene_2_1])
      expect(preloaded.french_scenes).to eq([fs_1_2_a, fs_2_1_a])
    end

    it 'still assigns content by id' do
      rehearsal.update!(scene_ids: [scene_2_1.id, scene_1_2.id], french_scene_ids: [fs_2_1_a.id, fs_1_2_a.id])
      expect(rehearsal.reload.scene_ids).to eq([scene_1_2.id, scene_2_1.id])
      expect(rehearsal.french_scene_ids).to eq([fs_1_2_a.id, fs_2_1_a.id])
    end

    it 'lists content in play order in the calendar description' do
      rehearsal.scenes << scene_2_1 << scene_1_2
      rehearsal.french_scenes << fs_2_1_a << fs_1_2_a
      expect(rehearsal.reload.text_unit_content).to eq('01.02, 02.01, 01.02.a, 02.01.a')
    end
  end

  describe 'changing the call list' do
    let(:rehearsal) { create(:rehearsal) }
    let(:user) { create(:user) }

    it 'touches the rehearsal when someone is added' do
      expect { rehearsal.users << user }.to change { rehearsal.reload.updated_at }
    end

    it 'touches the rehearsal when someone is removed' do
      rehearsal.users << user
      expect { rehearsal.user_ids = [] }.to change { rehearsal.reload.updated_at }
    end

    it 'does not touch an unsaved rehearsal' do
      new_rehearsal = build(:rehearsal)
      expect { new_rehearsal.users << user }.not_to raise_error
      expect(new_rehearsal).to be_new_record
    end
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
