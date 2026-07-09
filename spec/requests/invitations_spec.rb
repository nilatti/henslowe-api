require 'rails_helper'

RSpec.describe 'invitations API', type: :request do
  let!(:theater) { create(:theater) }
  let!(:admin_user) { create(:user, :paid) }
  let!(:theater_admin_job) do
    create(:job, user: admin_user, theater: theater, production: nil,
                 specialization: create(:specialization, :theater_admin))
  end
  let!(:director_spec) { create(:specialization, :director) }
  let!(:regular_user) { create(:user) }

  before { allow(InvitationMailer).to receive(:invite).and_return(double(deliver_later: true)) }

  describe 'POST /theaters/:theater_id/invitations' do
    let(:params) do
      { invitation: { email: 'someone@example.com', specialization_id: director_spec.id, payment_responsibility: 'self_pays' } }
    end

    context 'as a theater admin' do
      before { post "/api/v1/theaters/#{theater.id}/invitations", params: params, as: :json, headers: authenticated_header(admin_user) }

      it 'creates a pending invitation' do
        expect(response).to have_http_status(:created)
        expect(json['status']).to eq('pending')
        expect(json['email']).to eq('someone@example.com')
      end

      it 'sends the invitation email' do
        expect(InvitationMailer).to have_received(:invite).with(Invitation.last.id)
      end
    end

    context 'as a non-admin' do
      before { post "/api/v1/theaters/#{theater.id}/invitations", params: params, as: :json, headers: authenticated_header(regular_user) }

      it 'is forbidden' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'inviting to an Actor role' do
      let(:params) do
        { invitation: { email: 'someone@example.com', specialization_id: create(:specialization, :actor).id, payment_responsibility: 'self_pays' } }
      end

      before { post "/api/v1/theaters/#{theater.id}/invitations", params: params, as: :json, headers: authenticated_header(admin_user) }

      it 'is rejected' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when the request body also carries a production_id (as StaffJobsList/InviteForm send for production-context invites)' do
      let(:params) do
        { invitation: { email: 'someone@example.com', specialization_id: director_spec.id, payment_responsibility: 'self_pays', production_id: 9999 } }
      end

      before { post "/api/v1/theaters/#{theater.id}/invitations", params: params, as: :json, headers: authenticated_header(admin_user) }

      it 'ignores the body production_id and stays scoped to the theater' do
        expect(response).to have_http_status(:created)
        expect(Invitation.last.theater_id).to eq(theater.id)
        expect(Invitation.last.production_id).to be_nil
      end
    end
  end

  describe 'POST /productions/:production_id/invitations' do
    let!(:production) { create(:production, theater: theater) }
    let!(:production_admin_job) do
      create(:job, user: admin_user, theater: nil, production: production,
                   specialization: create(:specialization, :production_admin))
    end
    let(:params) do
      { invitation: { email: 'someone@example.com', specialization_id: director_spec.id, payment_responsibility: 'self_pays' } }
    end

    it 'creates an invitation scoped to the production' do
      post "/api/v1/productions/#{production.id}/invitations", params: params, as: :json, headers: authenticated_header(admin_user)
      expect(response).to have_http_status(:created)
      expect(Invitation.last.production_id).to eq(production.id)
      expect(Invitation.last.theater_id).to be_nil
    end

    context 'when the request body also carries the parent theater_id (as the frontend sends today)' do
      let(:params) do
        { invitation: { email: 'someone@example.com', specialization_id: director_spec.id, payment_responsibility: 'self_pays', theater_id: theater.id } }
      end

      it 'ignores the body theater_id and stays scoped to the production' do
        post "/api/v1/productions/#{production.id}/invitations", params: params, as: :json, headers: authenticated_header(admin_user)
        expect(response).to have_http_status(:created)
        expect(Invitation.last.production_id).to eq(production.id)
        expect(Invitation.last.theater_id).to be_nil
      end
    end
  end

  describe 'GET /invitations/:token' do
    let!(:invitation) { create(:invitation, theater: theater, specialization: director_spec, invited_by: admin_user) }

    it 'is readable without authentication' do
      get "/api/v1/invitations/#{invitation.token}", as: :json
      expect(response).to have_http_status(:ok)
      expect(json['email']).to eq(invitation.email)
    end
  end

  describe 'POST /invitations/:token/accept' do
    let!(:invitation) do
      create(:invitation, theater: theater, specialization: director_spec, invited_by: admin_user,
                           email: matching_user.email, payment_responsibility: 'self_pays')
    end
    let(:matching_user) { create(:user, :paid) }

    context 'when the accepting user email matches' do
      before { post "/api/v1/invitations/#{invitation.token}/accept", as: :json, headers: authenticated_header(matching_user) }

      it 'creates a Job for the accepting user' do
        expect(response).to have_http_status(:created)
        expect(Job.where(user: matching_user, theater: theater, specialization: director_spec)).to exist
      end

      it 'marks the invitation accepted' do
        expect(invitation.reload.status).to eq('accepted')
        expect(invitation.accepted_user_id).to eq(matching_user.id)
      end
    end

    context 'when the accepting user email does not match' do
      let(:other_user) { create(:user, :paid) }
      before { post "/api/v1/invitations/#{invitation.token}/accept", as: :json, headers: authenticated_header(other_user) }

      it 'is forbidden' do
        expect(response).to have_http_status(:forbidden)
        expect(invitation.reload.status).to eq('pending')
      end
    end

    context 'when the matching user is not subscribed' do
      let(:matching_user) { create(:user) }
      before { post "/api/v1/invitations/#{invitation.token}/accept", as: :json, headers: authenticated_header(matching_user) }

      it 'surfaces payment_required and leaves the invitation pending' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['base']).to include('payment_required')
        expect(invitation.reload.status).to eq('pending')
      end
    end

    context 'when the invitation has expired' do
      let!(:invitation) do
        create(:invitation, :expired, theater: theater, specialization: director_spec, invited_by: admin_user,
                             email: matching_user.email, payment_responsibility: 'self_pays')
      end

      before { post "/api/v1/invitations/#{invitation.token}/accept", as: :json, headers: authenticated_header(matching_user) }

      it 'is rejected and marks the invitation expired' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(invitation.reload.status).to eq('expired')
      end
    end
  end

  describe 'DELETE /invitations/:token' do
    let!(:invitation) { create(:invitation, theater: theater, specialization: director_spec, invited_by: admin_user) }

    it 'revokes the invitation for a theater admin' do
      delete "/api/v1/invitations/#{invitation.token}", as: :json, headers: authenticated_header(admin_user)
      expect(response).to have_http_status(:no_content)
      expect(invitation.reload.status).to eq('revoked')
    end

    it 'is forbidden for a non-admin' do
      delete "/api/v1/invitations/#{invitation.token}", as: :json, headers: authenticated_header(regular_user)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
