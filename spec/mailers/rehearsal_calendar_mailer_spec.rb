require 'rails_helper'
require 'icalendar'

RSpec.describe RehearsalCalendarMailer, type: :mailer do
  let(:space) { create(:space, name: 'Studio B') }
  let(:user) { create(:user, email: 'actor@example.com') }
  let(:rehearsal) do
    create(:rehearsal, title: 'Act 1 run', notes: 'Bring scripts', space: space,
      start_time: Time.zone.parse('2026-08-01 18:00:00 UTC'), end_time: Time.zone.parse('2026-08-01 20:00:00 UTC'))
  end

  def ics_for(mail)
    Icalendar::Calendar.parse(mail.attachments['invite.ics'].body.to_s).first
  end

  describe '#invite' do
    subject(:mail) { described_class.invite(rehearsal.id, user.id, 2) }

    it 'sends to the invited user' do
      expect(mail.to).to eq(['actor@example.com'])
    end

    it 'attaches a text/calendar REQUEST' do
      expect(mail.attachments['invite.ics'].content_type).to include('method=REQUEST')
    end

    it 'builds a VEVENT with the rehearsal details' do
      event = ics_for(mail).events.first
      expect(event.summary.to_s).to eq('Act 1 run')
      expect(event.location.to_s).to eq('Studio B')
      expect(event.uid.to_s).to eq("rehearsal-#{rehearsal.id}@henslowescloud.com")
      expect(event.sequence.to_i).to eq(2)
      expect(event.status.to_s).to eq('CONFIRMED')
    end

    it 'stamps DTSTART/DTEND in UTC' do
      event = ics_for(mail).events.first
      expect(event.dtstart.utc?).to be true
      expect(event.dtend.utc?).to be true
    end
  end

  describe '#cancel' do
    subject(:mail) { described_class.cancel(rehearsal.id, user.id, 3) }

    it 'attaches a text/calendar CANCEL with the same UID' do
      expect(mail.attachments['invite.ics'].content_type).to include('method=CANCEL')
      event = ics_for(mail).events.first
      expect(event.uid.to_s).to eq("rehearsal-#{rehearsal.id}@henslowescloud.com")
      expect(event.status.to_s).to eq('CANCELLED')
      expect(event.sequence.to_i).to eq(3)
    end
  end

  describe '#cancel_deleted' do
    let(:snapshot) do
      {
        uid: "rehearsal-#{rehearsal.id}@henslowescloud.com",
        sequence: 4,
        summary: 'Act 1 run',
        description: 'Bring scripts',
        location: 'Studio B',
        start_time: rehearsal.start_time,
        end_time: rehearsal.end_time,
      }
    end
    subject(:mail) { described_class.cancel_deleted(snapshot, user.id) }

    it 'builds the cancellation from the snapshot without touching the (deleted) rehearsal' do
      event = ics_for(mail).events.first
      expect(event.uid.to_s).to eq(snapshot[:uid])
      expect(event.sequence.to_i).to eq(4)
      expect(event.status.to_s).to eq('CANCELLED')
      expect(mail.subject).to include('Act 1 run')
    end
  end
end
