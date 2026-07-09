require 'rails_helper'

RSpec.describe InvitationMailer, type: :mailer do
  let(:theater) { create(:theater, name: 'Silkmoth Stage') }
  let(:inviter) { create(:user, first_name: 'Ada', last_name: 'Lovelace') }
  let(:director_spec) { create(:specialization, :director) }
  let(:invitation) do
    create(:invitation, email: 'someone@example.com', theater: theater, specialization: director_spec, invited_by: inviter)
  end

  subject(:mail) { InvitationMailer.invite(invitation.id) }

  describe '#invite' do
    it 'sends to the invited email' do
      expect(mail.to).to eq(['someone@example.com'])
    end

    it 'includes the theater name in the subject' do
      expect(mail.subject).to include('Silkmoth Stage')
    end

    it 'builds an absolute accept URL from FRONTEND_URL, not the unset BASE_URL_FRONT' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('FRONTEND_URL').and_return('https://henslowescloud.com')
      expect(mail.html_part.body.encoded).to include("https://henslowescloud.com/invitations/#{invitation.token}")
    end

    it 'includes the inviter and role in the body' do
      expect(mail.html_part.body.encoded).to include('Ada Lovelace')
      expect(mail.html_part.body.encoded).to include('Director')
    end
  end
end
