require 'rails_helper'

RSpec.describe 'auditions API', type: :request do
  let(:user)       { create(:user) }
  let(:production) { create(:production) }
  let(:prod_admin_specialization) { create(:specialization, :production_admin) }
  let(:admin_user) { create(:user, :paid, email: 'director@example.com') }

  before do
    create(:specialization, :auditioner)
    create(:job, user: admin_user, production: production, specialization: prod_admin_specialization)
  end

  describe 'POST /api/v1/productions/:production_id/auditions' do
    context 'with valid params' do
      it 'returns 201' do
        post "/api/v1/productions/#{production.id}/auditions",
          params: { audition_submission: { video_url: 'https://youtu.be/xyz', notes: 'Hi!' } },
          as: :json,
          headers: authenticated_header(user)
        expect(response).to have_http_status(201)
      end

      it 'creates an auditioner job for the current user' do
        expect {
          post "/api/v1/productions/#{production.id}/auditions",
            as: :json,
            headers: authenticated_header(user)
        }.to change { Job.where(user: user, production: production).count }.by(1)
      end

      it 'saves the submission when params are provided' do
        post "/api/v1/productions/#{production.id}/auditions",
          params: { audition_submission: { video_url: 'https://youtu.be/xyz', notes: 'Available weekends' } },
          as: :json,
          headers: authenticated_header(user)
        job = Job.find(json['id'])
        expect(job.audition_submission.video_url).to eq('https://youtu.be/xyz')
        expect(job.audition_submission.notes).to eq('Available weekends')
      end

      it 'does not create a duplicate job on re-submission' do
        post "/api/v1/productions/#{production.id}/auditions", as: :json, headers: authenticated_header(user)
        expect {
          post "/api/v1/productions/#{production.id}/auditions", as: :json, headers: authenticated_header(user)
        }.not_to change { Job.count }
      end

      it 'enqueues a notification email to production admins' do
        expect {
          post "/api/v1/productions/#{production.id}/auditions",
            as: :json,
            headers: authenticated_header(user)
        }.to have_enqueued_mail(AuditionMailer, :new_submission)
      end
    end

    context 'when the production does not exist' do
      it 'returns 404' do
        post "/api/v1/productions/99999/auditions", as: :json, headers: authenticated_header(user)
        expect(response).to have_http_status(404)
      end
    end
  end
end
