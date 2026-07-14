require 'rails_helper'

RSpec.describe PublishRehearsalCalendar do
  let(:production) { create(:production) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  def run
    described_class.new(production).run
  end

  describe 'a brand new rehearsal' do
    let!(:rehearsal) do
      r = create(:rehearsal, production: production, start_time: 1.day.from_now, end_time: 1.day.from_now + 2.hours)
      r.user_ids = [user1.id, user2.id]
      r
    end

    it 'sends an invite to the first person on the call list' do
      expect { run }.to have_enqueued_mail(RehearsalCalendarMailer, :invite).with(rehearsal.id, user1.id, 0)
    end

    it 'sends an invite to the second person on the call list' do
      expect { run }.to have_enqueued_mail(RehearsalCalendarMailer, :invite).with(rehearsal.id, user2.id, 0)
    end

    it 'records a rehearsal_invite row per recipient' do
      run
      expect(rehearsal.rehearsal_invites.pluck(:user_id)).to contain_exactly(user1.id, user2.id)
    end

    it 'sets published_at to the rehearsal updated_at' do
      run
      rehearsal.reload
      expect(rehearsal.published_at).to eq(rehearsal.updated_at)
    end
  end

  describe 'a rehearsal that is already fully published' do
    let!(:rehearsal) do
      r = create(:rehearsal, production: production, start_time: 1.day.from_now, end_time: 1.day.from_now + 2.hours)
      r.user_ids = [user1.id]
      r
    end

    before { run }

    it 'does not send anything on a second run' do
      expect { run }.not_to have_enqueued_mail(RehearsalCalendarMailer)
    end

    it 'does not bump the ics_sequence' do
      expect { run }.not_to change { rehearsal.reload.ics_sequence }
    end
  end

  describe 'adding one more person to an already-published call list, with nothing else changed' do
    let!(:rehearsal) do
      r = create(:rehearsal, production: production, start_time: 1.day.from_now, end_time: 1.day.from_now + 2.hours)
      r.user_ids = [user1.id]
      r
    end

    before do
      run
      rehearsal.user_ids = [user1.id, user2.id]
    end

    it 'emails only the newly added person' do
      expect { run }.to have_enqueued_mail(RehearsalCalendarMailer, :invite).with(rehearsal.id, user2.id, 0)
    end

    it 'does not re-email the person who was already invited' do
      expect { run }.to have_enqueued_mail(RehearsalCalendarMailer, :invite).exactly(1).times
    end

    it 'does not bump the ics_sequence' do
      expect { run }.not_to change { rehearsal.reload.ics_sequence }
    end
  end

  describe 'changing a schedule detail (e.g. start_time)' do
    let!(:rehearsal) do
      r = create(:rehearsal, production: production, start_time: 1.day.from_now, end_time: 1.day.from_now + 2.hours)
      r.user_ids = [user1.id, user2.id]
      r
    end

    before do
      run
      rehearsal.update!(start_time: rehearsal.start_time + 30.minutes)
    end

    it 'resends to the first person with a bumped sequence' do
      expect { run }.to have_enqueued_mail(RehearsalCalendarMailer, :invite).with(rehearsal.id, user1.id, 1)
    end

    it 'resends to the second person with a bumped sequence' do
      expect { run }.to have_enqueued_mail(RehearsalCalendarMailer, :invite).with(rehearsal.id, user2.id, 1)
    end

    it 'bumps the ics_sequence exactly once' do
      expect { run }.to change { rehearsal.reload.ics_sequence }.from(0).to(1)
    end
  end

  describe 'removing someone from the call list' do
    let!(:rehearsal) do
      r = create(:rehearsal, production: production, start_time: 1.day.from_now, end_time: 1.day.from_now + 2.hours)
      r.user_ids = [user1.id, user2.id]
      r
    end

    before do
      run
      rehearsal.user_ids = [user1.id]
    end

    it 'sends a cancellation to the removed person' do
      expect { run }.to have_enqueued_mail(RehearsalCalendarMailer, :cancel).with(rehearsal.id, user2.id, 0)
    end

    it 'destroys their rehearsal_invite row so a future re-add sends a fresh invite' do
      run
      expect(rehearsal.rehearsal_invites.pluck(:user_id)).to contain_exactly(user1.id)
    end
  end

  describe 'a rehearsal in the past' do
    let!(:rehearsal) do
      r = create(:rehearsal, production: production, start_time: 1.day.ago, end_time: 1.day.ago + 2.hours)
      r.user_ids = [user1.id]
      r
    end

    it 'is never published' do
      expect { run }.not_to have_enqueued_mail(RehearsalCalendarMailer)
      expect(rehearsal.reload.published_at).to be_nil
    end
  end

  describe 'a rehearsal belonging to a different production' do
    let!(:other_production) { create(:production) }
    let!(:rehearsal) do
      r = create(:rehearsal, production: other_production, start_time: 1.day.from_now, end_time: 1.day.from_now + 2.hours)
      r.user_ids = [user1.id]
      r
    end

    it 'is not touched' do
      expect { run }.not_to have_enqueued_mail(RehearsalCalendarMailer)
    end
  end
end
