require 'rails_helper'

RSpec.describe AuditionMailer, type: :mailer do
  let(:production) { create(:production) }
  let(:auditioner) { create(:user, first_name: 'Ada', last_name: 'Lovelace', email: 'ada@example.com', phone_number: '555-1234') }
  let(:admin1)     { create(:user, :paid, email: 'director@example.com') }
  let(:admin2)     { create(:user, :paid, email: 'producer@example.com') }
  let(:prod_admin_specialization) { create(:specialization, :production_admin) }

  let!(:auditioner_job) do
    create(:job, :auditioner_job, user: auditioner, production: production)
  end

  let!(:admin_job1) { create(:job, user: admin1, production: production, specialization: prod_admin_specialization) }
  let!(:admin_job2) { create(:job, user: admin2, production: production, specialization: prod_admin_specialization) }

  subject(:mail) { AuditionMailer.new_submission(auditioner_job.id) }

  describe '#new_submission' do
    it 'sends to all production admins' do
      expect(mail.to).to match_array(['director@example.com', 'producer@example.com'])
    end

    it 'includes the play title in the subject' do
      expect(mail.subject).to include(production.play.title)
    end

    it 'includes the auditioner name in the HTML body' do
      expect(mail.html_part.body.encoded).to include('Ada Lovelace')
    end

    it 'includes the auditioner email in the HTML body' do
      expect(mail.html_part.body.encoded).to include('ada@example.com')
    end

    it 'includes the auditioner phone in the HTML body' do
      expect(mail.html_part.body.encoded).to include('555-1234')
    end

    it 'includes the auditioner name in the text body' do
      expect(mail.text_part.body.encoded).to include('Ada Lovelace')
    end

    it 'includes a link to the submission in the HTML body' do
      expect(mail.html_part.body.encoded).to include("/auditions/#{auditioner_job.id}")
    end

    context 'when a video URL is submitted' do
      before { create(:audition_submission, job: auditioner_job, video_url: 'https://youtu.be/abc') }

      it 'includes the video URL in the HTML body' do
        expect(mail.html_part.body.encoded).to include('https://youtu.be/abc')
      end
    end

    context 'when notes are submitted' do
      before { create(:audition_submission, job: auditioner_job, notes: 'Available weekends only') }

      it 'includes the notes in the HTML body' do
        expect(mail.html_part.body.encoded).to include('Available weekends only')
      end
    end

    context 'when there are no production admins' do
      before do
        admin_job1.destroy
        admin_job2.destroy
      end

      it 'sends to an empty recipient list without raising' do
        expect { mail.deliver_now }.not_to raise_error
      end
    end

    context 'when another production has an admin' do
      let(:other_production) { create(:production) }
      let!(:other_admin_job) do
        create(:job, user: create(:user, :paid, email: 'other@example.com'),
               production: other_production, specialization: prod_admin_specialization)
      end

      it 'does not include admins from other productions' do
        expect(mail.to).not_to include('other@example.com')
      end
    end
  end
end
