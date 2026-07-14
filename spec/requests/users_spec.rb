# spec/requests/users_spec.rb
require 'rails_helper'
require 'base64'
require 'stringio'
require 'aws-sdk-s3'

RSpec.describe 'Users API' do
  let!(:user) { create(:user) }
  let!(:jobs) { create_list(:job, 3, user: user) }
  let!(:conflicts) { create_list(:conflict, 5, user: user) }
  let!(:users) { create_list(:user, 10) }
  let!(:id) { user.id }
  let!(:space) { create(:space) }

  def valid_png_bytes
    Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=')
  end

  def valid_pdf_bytes
    "%PDF-1.4\n%%EOF"
  end

  def uploaded_file(content, content_type:, filename:)
    Rack::Test::UploadedFile.new(StringIO.new(content), content_type, original_filename: filename)
  end

  describe 'GET api/users' do
    it 'returns status code 200' do
      get "/api/v1/users/", headers: authenticated_header(user)
      expect(response).to have_http_status(200)
    end

    context 'when requester has no shared theater or production with others' do
      it 'returns only the requester' do
        get "/api/v1/users/", headers: authenticated_header(user)
        expect(json.map { |u| u['id'] }).to contain_exactly(user.id)
      end
    end

    context 'when requester has a theater-level job' do
      let!(:theater) { create(:theater) }
      let!(:production) { create(:production, theater: theater) }
      let!(:actor_spec) { create(:specialization, :actor) }
      let!(:theater_job) { create(:job, user: user, theater: theater, production: nil, specialization: actor_spec, end_date: nil) }
      let!(:theater_peer) { create(:user) }
      let!(:theater_peer_job) { create(:job, user: theater_peer, theater: theater, production: nil, specialization: actor_spec, end_date: nil) }
      let!(:production_worker) { create(:user) }
      let!(:production_worker_job) { create(:job, user: production_worker, production: production, specialization: actor_spec, end_date: nil) }
      let!(:unrelated_user) { create(:user) }

      it 'includes users with theater jobs at the same theater' do
        get "/api/v1/users/", headers: authenticated_header(user)
        expect(json.map { |u| u['id'] }).to include(theater_peer.id)
      end

      it "includes users with production jobs on that theater's productions" do
        get "/api/v1/users/", headers: authenticated_header(user)
        expect(json.map { |u| u['id'] }).to include(production_worker.id)
      end

      it 'excludes users with no shared context' do
        get "/api/v1/users/", headers: authenticated_header(user)
        expect(json.map { |u| u['id'] }).not_to include(unrelated_user.id)
      end
    end

    context 'when requester has a production job' do
      let!(:theater) { create(:theater) }
      let!(:actor_spec) { create(:specialization, :actor) }
      let!(:production) { create(:production, theater: theater) }
      let!(:other_production) { create(:production, theater: theater) }
      let!(:production_job) { create(:job, user: user, production: production, specialization: actor_spec, end_date: nil) }
      let!(:theater_worker) { create(:user) }
      let!(:theater_worker_job) { create(:job, user: theater_worker, theater: theater, production: nil, specialization: actor_spec, end_date: nil) }
      let!(:production_peer) { create(:user) }
      let!(:production_peer_job) { create(:job, user: production_peer, production: production, specialization: actor_spec, end_date: nil) }
      let!(:other_production_user) { create(:user) }
      let!(:other_production_job) { create(:job, user: other_production_user, production: other_production, specialization: actor_spec, end_date: nil) }

      it "includes users with theater jobs at the production's theater" do
        get "/api/v1/users/", headers: authenticated_header(user)
        expect(json.map { |u| u['id'] }).to include(theater_worker.id)
      end

      it 'includes users with production jobs on the same production' do
        get "/api/v1/users/", headers: authenticated_header(user)
        expect(json.map { |u| u['id'] }).to include(production_peer.id)
      end

      it 'excludes users with production jobs on other productions' do
        get "/api/v1/users/", headers: authenticated_header(user)
        expect(json.map { |u| u['id'] }).not_to include(other_production_user.id)
      end
    end

    context 'when requester is a superadmin' do
      let!(:superadmin) { create(:user, role: 'superadmin') }

      it 'returns all users' do
        get "/api/v1/users/", headers: authenticated_header(superadmin)
        returned_ids = json.map { |u| u['id'] }
        expect(returned_ids).to include(user.id, superadmin.id)
        users.each { |u| expect(returned_ids).to include(u.id) }
      end
    end
  end

  describe 'GET /users/:user_id/' do
    before { get "/api/v1/users/#{id}/", headers: authenticated_header(user) }

    context 'when user exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the user' do
        expect(json['id']).to eq(user.id)
      end
    end

    context 'when user does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find User/)
      end
    end
  end

  describe 'PUT /api/v1/users/:id with receive_rehearsal_calendar_invites' do
    before do
      put "/api/v1/users/#{id}", params: { user: { receive_rehearsal_calendar_invites: false } }, as: :json, headers: authenticated_header(user)
    end

    it 'persists the preference' do
      expect(user.reload.receive_rehearsal_calendar_invites).to eq(false)
    end

    it 'round-trips through the show endpoint' do
      get "/api/v1/users/#{id}/", headers: authenticated_header(user)
      expect(json['receive_rehearsal_calendar_invites']).to eq(false)
    end
  end

  describe 'access user data' do
    context 'when user is self' do
      before {
        login_user(user)
        get "/api/v1/users/#{id}/", headers: authenticated_header(user)
      }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all user information with overlap self' do
        expect(json['bio']).to eq(user.bio)
        expect(Date.parse(json['birthdate'])).to eq(user.birthdate)
        expect(json['city']).to eq(user.city)
        expect(json['conflicts'].size).to eq(user.conflicts.size)
        expect(json['description']).to eq(user.description)
        expect(json['email']).to eq(user.email)
        expect(json['emergency_contact_name']).to eq(user.emergency_contact_name)
        expect(json['emergency_contact_number']).to eq(user.emergency_contact_number)
        expect(json['first_name']).to eq(user.first_name)
        expect(json['gender']).to eq(user.gender)
        expect(json['id']).to eq(user.id)
        expect(json['jobs'].size).to eq(user.jobs.size)
        expect(json['last_name']).to eq(user.last_name)
        expect(json['middle_name']).to eq(user.middle_name)
        expect(json['phone_number']).to eq(user.phone_number)
        expect(json['program_name']).to eq(user.program_name)
        expect(json['preferred_name']).to eq(user.preferred_name)
        expect(json['state']).to eq(user.state)
        expect(json['street_address']).to eq(user.street_address)
        expect(json['timezone']).to eq(user.timezone)
        expect(json['website']).to eq(user.website)
        expect(json['zip']).to eq(user.zip)
        expect(json['overlap']).to eq('self')
      end
    end

    context 'when user is super user' do
      let!(:super_user) { create(:user, role: "superadmin") }
      before {
        login_user(super_user)
        get "/api/v1/users/#{id}/", headers: authenticated_header(super_user)
      }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all user information with overlap superadmin' do
        expect(json['bio']).to eq(user.bio)
        expect(Date.parse(json['birthdate'])).to eq(user.birthdate)
        expect(json['city']).to eq(user.city)
        expect(json['conflicts'].size).to eq(user.conflicts.size)
        expect(json['description']).to eq(user.description)
        expect(json['email']).to eq(user.email)
        expect(json['emergency_contact_name']).to eq(user.emergency_contact_name)
        expect(json['emergency_contact_number']).to eq(user.emergency_contact_number)
        expect(json['first_name']).to eq(user.first_name)
        expect(json['gender']).to eq(user.gender)
        expect(json['id']).to eq(user.id)
        expect(json['jobs'].size).to eq(user.jobs.size)
        expect(json['last_name']).to eq(user.last_name)
        expect(json['middle_name']).to eq(user.middle_name)
        expect(json['phone_number']).to eq(user.phone_number)
        expect(json['program_name']).to eq(user.program_name)
        expect(json['preferred_name']).to eq(user.preferred_name)
        expect(json['state']).to eq(user.state)
        expect(json['street_address']).to eq(user.street_address)
        expect(json['timezone']).to eq(user.timezone)
        expect(json['website']).to eq(user.website)
        expect(json['zip']).to eq(user.zip)
        expect(json['overlap']).to eq('superadmin')
      end
    end

    context 'when user is theater admin' do
      let!(:local_theater) { create(:theater) }
      let!(:theater_admin_user) { create(:user, :paid) }
      let!(:theater_admin_job) { create(:job, :admin_job, user: theater_admin_user, theater: local_theater, end_date: nil) }

      it 'returns full data for a user who works at the theater' do
        login_user(theater_admin_user)
        user_who_works_at_theater = create(:user)
        create(:job, user: user_who_works_at_theater, theater: local_theater, end_date: nil)
        get "/api/v1/users/#{user_who_works_at_theater.id}/", headers: authenticated_header(theater_admin_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(user_who_works_at_theater.bio)
        expect(Date.parse(json['birthdate'])).to eq(user_who_works_at_theater.birthdate)
        expect(json['city']).to eq(user_who_works_at_theater.city)
        expect(json['conflicts'].size).to eq(user_who_works_at_theater.conflicts.size)
        expect(json['description']).to eq(user_who_works_at_theater.description)
        expect(json['email']).to eq(user_who_works_at_theater.email)
        expect(json['emergency_contact_name']).to eq(user_who_works_at_theater.emergency_contact_name)
        expect(json['emergency_contact_number']).to eq(user_who_works_at_theater.emergency_contact_number)
        expect(json['first_name']).to eq(user_who_works_at_theater.first_name)
        expect(json['gender']).to eq(user_who_works_at_theater.gender)
        expect(json['id']).to eq(user_who_works_at_theater.id)
        expect(json['jobs'].size).to eq(user_who_works_at_theater.jobs.size)
        expect(json['last_name']).to eq(user_who_works_at_theater.last_name)
        expect(json['middle_name']).to eq(user_who_works_at_theater.middle_name)
        expect(json['phone_number']).to eq(user_who_works_at_theater.phone_number)
        expect(json['program_name']).to eq(user_who_works_at_theater.program_name)
        expect(json['preferred_name']).to eq(user_who_works_at_theater.preferred_name)
        expect(json['state']).to eq(user_who_works_at_theater.state)
        expect(json['street_address']).to eq(user_who_works_at_theater.street_address)
        expect(json['timezone']).to eq(user_who_works_at_theater.timezone)
        expect(json['website']).to eq(user_who_works_at_theater.website)
        expect(json['zip']).to eq(user_who_works_at_theater.zip)
        expect(json['overlap']).to eq('theater admin')
      end

      it 'returns non-admin info for a user with no jobs' do
        login_user(theater_admin_user)
        other_user = create(:user)
        get "/api/v1/users/#{other_user.id}/", headers: authenticated_header(theater_admin_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_user.bio)
        expect(json['city']).to be_nil
        expect(json['description']).to be_nil
        expect(json['email']).to eq(other_user.email)
        expect(json['first_name']).to eq(other_user.first_name)
        expect(json['gender']).to eq(other_user.gender)
        expect(json['id']).to eq(other_user.id)
        expect(json['jobs']).to be_nil
        expect(json['last_name']).to eq(other_user.last_name)
        expect(json['middle_name']).to eq(other_user.middle_name)
        expect(json['phone_number']).to eq(other_user.phone_number)
        expect(json['program_name']).to eq(other_user.program_name)
        expect(json['preferred_name']).to eq(other_user.preferred_name)
        expect(json['state']).to be_nil
        expect(json['website']).to eq(other_user.website)
        expect(json['overlap']).to eq('none')
      end

      it 'returns non-admin info for a user at an unrelated theater' do
        other_user = create(:user)
        other_theater = create(:theater)
        create_list(:job, 3, user: other_user, theater: other_theater)
        login_user(theater_admin_user)
        get "/api/v1/users/#{other_user.id}/", headers: authenticated_header(theater_admin_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_user.bio)
        expect(json['city']).to be_nil
        expect(json['description']).to be_nil
        expect(json['email']).to eq(other_user.email)
        expect(json['first_name']).to eq(other_user.first_name)
        expect(json['gender']).to eq(other_user.gender)
        expect(json['id']).to eq(other_user.id)
        expect(json['jobs']).to be_nil
        expect(json['last_name']).to eq(other_user.last_name)
        expect(json['phone_number']).to eq(other_user.phone_number)
        expect(json['program_name']).to eq(other_user.program_name)
        expect(json['preferred_name']).to eq(other_user.preferred_name)
        expect(json['state']).to be_nil
        expect(json['website']).to eq(other_user.website)
        expect(json['overlap']).to eq('none')
      end

      it 'returns non-admin info for a past employee' do
        past_employee = create(:user)
        create(:job, start_date: Date.today - 9.years, end_date: Date.today - 8.years, theater: local_theater, user: past_employee)
        login_user(theater_admin_user)
        get "/api/v1/users/#{past_employee.id}/", headers: authenticated_header(theater_admin_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(past_employee.bio)
        expect(json['city']).to be_nil
        expect(json['description']).to be_nil
        expect(json['email']).to eq(past_employee.email)
        expect(json['first_name']).to eq(past_employee.first_name)
        expect(json['gender']).to eq(past_employee.gender)
        expect(json['id']).to eq(past_employee.id)
        expect(json['jobs']).to be_nil
        expect(json['last_name']).to eq(past_employee.last_name)
        expect(json['phone_number']).to eq(past_employee.phone_number)
        expect(json['program_name']).to eq(past_employee.program_name)
        expect(json['preferred_name']).to eq(past_employee.preferred_name)
        expect(json['state']).to be_nil
        expect(json['website']).to eq(past_employee.website)
        expect(json['overlap']).to eq('past peer')
      end
    end

    context 'when user is production admin' do
      let!(:local_theater) { create(:theater) }
      let!(:local_production) { create(:production) }
      let!(:production_admin_user) { create(:user, :paid) }
      let!(:director_spec) { create(:specialization, :director) }
      let!(:production_admin_job) { create(:job, user: production_admin_user, theater: local_theater, production: local_production, specialization: director_spec, end_date: nil) }

      it 'returns full data for a user on the same production' do
        login_user(production_admin_user)
        coworker = create(:user)
        create(:job, user: coworker, theater: local_theater, production: local_production, end_date: nil)
        get "/api/v1/users/#{coworker.id}/", headers: authenticated_header(production_admin_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(coworker.bio)
        expect(Date.parse(json['birthdate'])).to eq(coworker.birthdate)
        expect(json['city']).to eq(coworker.city)
        expect(json['conflicts'].size).to eq(coworker.conflicts.size)
        expect(json['description']).to eq(coworker.description)
        expect(json['email']).to eq(coworker.email)
        expect(json['emergency_contact_name']).to eq(coworker.emergency_contact_name)
        expect(json['emergency_contact_number']).to eq(coworker.emergency_contact_number)
        expect(json['first_name']).to eq(coworker.first_name)
        expect(json['gender']).to eq(coworker.gender)
        expect(json['id']).to eq(coworker.id)
        expect(json['jobs'].size).to eq(coworker.jobs.size)
        expect(json['last_name']).to eq(coworker.last_name)
        expect(json['middle_name']).to eq(coworker.middle_name)
        expect(json['phone_number']).to eq(coworker.phone_number)
        expect(json['program_name']).to eq(coworker.program_name)
        expect(json['preferred_name']).to eq(coworker.preferred_name)
        expect(json['state']).to eq(coworker.state)
        expect(json['street_address']).to eq(coworker.street_address)
        expect(json['timezone']).to eq(coworker.timezone)
        expect(json['website']).to eq(coworker.website)
        expect(json['zip']).to eq(coworker.zip)
        expect(json['overlap']).to eq('production admin')
      end

      it 'returns non-admin info for a user with no jobs' do
        login_user(production_admin_user)
        other_user = create(:user)
        get "/api/v1/users/#{other_user.id}/", headers: authenticated_header(production_admin_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_user.bio)
        expect(json['city']).to be_nil
        expect(json['description']).to be_nil
        expect(json['email']).to eq(other_user.email)
        expect(json['first_name']).to eq(other_user.first_name)
        expect(json['gender']).to eq(other_user.gender)
        expect(json['id']).to eq(other_user.id)
        expect(json['jobs']).to be_nil
        expect(json['last_name']).to eq(other_user.last_name)
        expect(json['middle_name']).to eq(other_user.middle_name)
        expect(json['phone_number']).to eq(other_user.phone_number)
        expect(json['program_name']).to eq(other_user.program_name)
        expect(json['preferred_name']).to eq(other_user.preferred_name)
        expect(json['state']).to be_nil
        expect(json['website']).to eq(other_user.website)
        expect(json['overlap']).to eq('none')
      end

      it 'returns non-admin info for a user at an unrelated theater' do
        other_user = create(:user)
        other_theater = create(:theater)
        create_list(:job, 3, user: other_user, theater: other_theater)
        login_user(production_admin_user)
        get "/api/v1/users/#{other_user.id}/", headers: authenticated_header(production_admin_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_user.bio)
        expect(json['city']).to be_nil
        expect(json['description']).to be_nil
        expect(json['email']).to eq(other_user.email)
        expect(json['first_name']).to eq(other_user.first_name)
        expect(json['gender']).to eq(other_user.gender)
        expect(json['id']).to eq(other_user.id)
        expect(json['jobs']).to be_nil
        expect(json['last_name']).to eq(other_user.last_name)
        expect(json['phone_number']).to eq(other_user.phone_number)
        expect(json['program_name']).to eq(other_user.program_name)
        expect(json['preferred_name']).to eq(other_user.preferred_name)
        expect(json['state']).to be_nil
        expect(json['website']).to eq(other_user.website)
        expect(json['overlap']).to eq('none')
      end

      it 'returns non-admin info for a past production member' do
        past_member = create(:user)
        create(:job, start_date: Date.today - 9.years, end_date: Date.today - 8.years, theater: local_theater, user: past_member, production: local_production)
        login_user(production_admin_user)
        get "/api/v1/users/#{past_member.id}/", headers: authenticated_header(production_admin_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(past_member.bio)
        expect(json['city']).to be_nil
        expect(json['description']).to be_nil
        expect(json['email']).to eq(past_member.email)
        expect(json['first_name']).to eq(past_member.first_name)
        expect(json['gender']).to eq(past_member.gender)
        expect(json['id']).to eq(past_member.id)
        expect(json['jobs']).to be_nil
        expect(json['last_name']).to eq(past_member.last_name)
        expect(json['phone_number']).to eq(past_member.phone_number)
        expect(json['program_name']).to eq(past_member.program_name)
        expect(json['preferred_name']).to eq(past_member.preferred_name)
        expect(json['state']).to be_nil
        expect(json['website']).to eq(past_member.website)
        expect(json['overlap']).to eq('past peer')
      end
    end

    context 'when user is a production peer (non-admin)' do
      let!(:local_theater) { create(:theater) }
      let!(:local_production) { create(:production) }
      let!(:production_user) { create(:user) }
      let!(:production_job) { create(:job, :actor_job, user: production_user, theater: local_theater, production: local_production, end_date: nil) }

      it 'returns non-admin info for a production peer' do
        login_user(production_user)
        peer = create(:user)
        create(:job, user: peer, theater: local_theater, production: local_production, end_date: nil)
        get "/api/v1/users/#{peer.id}/", headers: authenticated_header(production_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(peer.bio)
        expect(json['birthdate']).to be_nil
        expect(json['city']).to be_nil
        expect(json['conflicts']).to be_nil
        expect(json['description']).to be_nil
        expect(json['email']).to eq(peer.email)
        expect(json['emergency_contact_name']).to be_nil
        expect(json['emergency_contact_number']).to be_nil
        expect(json['first_name']).to eq(peer.first_name)
        expect(json['gender']).to eq(peer.gender)
        expect(json['id']).to eq(peer.id)
        expect(json['jobs']).to be_nil
        expect(json['last_name']).to eq(peer.last_name)
        expect(json['middle_name']).to eq(peer.middle_name)
        expect(json['phone_number']).to eq(peer.phone_number)
        expect(json['program_name']).to eq(peer.program_name)
        expect(json['preferred_name']).to eq(peer.preferred_name)
        expect(json['state']).to be_nil
        expect(json['street_address']).to be_nil
        expect(json['timezone']).to be_nil
        expect(json['website']).to eq(peer.website)
        expect(json['zip']).to be_nil
        expect(json['overlap']).to eq('production peer')
      end

      it 'returns non-admin info for a user with no jobs' do
        login_user(production_user)
        other_user = create(:user)
        get "/api/v1/users/#{other_user.id}/", headers: authenticated_header(production_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_user.bio)
        expect(json['birthdate']).to be_nil
        expect(json['city']).to be_nil
        expect(json['conflicts']).to be_nil
        expect(json['description']).to be_nil
        expect(json['email']).to eq(other_user.email)
        expect(json['emergency_contact_name']).to be_nil
        expect(json['emergency_contact_number']).to be_nil
        expect(json['first_name']).to eq(other_user.first_name)
        expect(json['gender']).to eq(other_user.gender)
        expect(json['id']).to eq(other_user.id)
        expect(json['jobs']).to be_nil
        expect(json['last_name']).to eq(other_user.last_name)
        expect(json['middle_name']).to eq(other_user.middle_name)
        expect(json['phone_number']).to eq(other_user.phone_number)
        expect(json['program_name']).to eq(other_user.program_name)
        expect(json['preferred_name']).to eq(other_user.preferred_name)
        expect(json['state']).to be_nil
        expect(json['street_address']).to be_nil
        expect(json['timezone']).to be_nil
        expect(json['website']).to eq(other_user.website)
        expect(json['overlap']).to eq('none')
      end

      it 'returns non-admin info for a user at an unrelated theater' do
        other_user = create(:user)
        other_theater = create(:theater)
        create_list(:job, 3, user: other_user, theater: other_theater)
        login_user(production_user)
        get "/api/v1/users/#{other_user.id}/", headers: authenticated_header(production_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_user.bio)
        expect(json['city']).to be_nil
        expect(json['description']).to be_nil
        expect(json['email']).to eq(other_user.email)
        expect(json['first_name']).to eq(other_user.first_name)
        expect(json['gender']).to eq(other_user.gender)
        expect(json['id']).to eq(other_user.id)
        expect(json['jobs']).to be_nil
        expect(json['last_name']).to eq(other_user.last_name)
        expect(json['phone_number']).to eq(other_user.phone_number)
        expect(json['program_name']).to eq(other_user.program_name)
        expect(json['preferred_name']).to eq(other_user.preferred_name)
        expect(json['state']).to be_nil
        expect(json['website']).to eq(other_user.website)
        expect(json['zip']).to be_nil
        expect(json['overlap']).to eq('none')
      end
    end

    context 'when user is a theater peer (non-admin)' do
      let!(:local_theater) { create(:theater) }
      let!(:theater_user) { create(:user) }
      let!(:theater_job) { create(:job, user: theater_user, theater: local_theater, end_date: nil) }

      it 'returns non-admin info for a theater peer' do
        login_user(theater_user)
        peer = create(:user)
        create(:job, user: peer, theater: local_theater, end_date: nil)
        get "/api/v1/users/#{peer.id}/", headers: authenticated_header(theater_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(peer.bio)
        expect(json['birthdate']).to be_nil
        expect(json['city']).to be_nil
        expect(json['conflicts']).to be_nil
        expect(json['description']).to be_nil
        expect(json['email']).to eq(peer.email)
        expect(json['emergency_contact_name']).to be_nil
        expect(json['emergency_contact_number']).to be_nil
        expect(json['first_name']).to eq(peer.first_name)
        expect(json['gender']).to eq(peer.gender)
        expect(json['id']).to eq(peer.id)
        expect(json['jobs']).to be_nil
        expect(json['last_name']).to eq(peer.last_name)
        expect(json['middle_name']).to eq(peer.middle_name)
        expect(json['phone_number']).to eq(peer.phone_number)
        expect(json['program_name']).to eq(peer.program_name)
        expect(json['preferred_name']).to eq(peer.preferred_name)
        expect(json['state']).to be_nil
        expect(json['street_address']).to be_nil
        expect(json['timezone']).to be_nil
        expect(json['website']).to eq(peer.website)
        expect(json['zip']).to be_nil
        expect(json['overlap']).to eq('theater peer')
      end

      it 'returns non-admin info for a user with no jobs' do
        login_user(theater_user)
        other_user = create(:user)
        get "/api/v1/users/#{other_user.id}/", headers: authenticated_header(theater_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_user.bio)
        expect(json['birthdate']).to be_nil
        expect(json['city']).to be_nil
        expect(json['conflicts']).to be_nil
        expect(json['description']).to be_nil
        expect(json['email']).to eq(other_user.email)
        expect(json['emergency_contact_name']).to be_nil
        expect(json['emergency_contact_number']).to be_nil
        expect(json['first_name']).to eq(other_user.first_name)
        expect(json['gender']).to eq(other_user.gender)
        expect(json['id']).to eq(other_user.id)
        expect(json['jobs']).to be_nil
        expect(json['last_name']).to eq(other_user.last_name)
        expect(json['middle_name']).to eq(other_user.middle_name)
        expect(json['phone_number']).to eq(other_user.phone_number)
        expect(json['program_name']).to eq(other_user.program_name)
        expect(json['preferred_name']).to eq(other_user.preferred_name)
        expect(json['state']).to be_nil
        expect(json['street_address']).to be_nil
        expect(json['timezone']).to be_nil
        expect(json['website']).to eq(other_user.website)
        expect(json['overlap']).to eq('none')
      end

      it 'returns non-admin info for a user at an unrelated theater' do
        other_user = create(:user)
        other_theater = create(:theater)
        create_list(:job, 3, user: other_user, theater: other_theater)
        login_user(theater_user)
        get "/api/v1/users/#{other_user.id}/", headers: authenticated_header(theater_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_user.bio)
        expect(json['city']).to be_nil
        expect(json['description']).to be_nil
        expect(json['email']).to eq(other_user.email)
        expect(json['first_name']).to eq(other_user.first_name)
        expect(json['gender']).to eq(other_user.gender)
        expect(json['id']).to eq(other_user.id)
        expect(json['jobs']).to be_nil
        expect(json['last_name']).to eq(other_user.last_name)
        expect(json['phone_number']).to eq(other_user.phone_number)
        expect(json['program_name']).to eq(other_user.program_name)
        expect(json['preferred_name']).to eq(other_user.preferred_name)
        expect(json['state']).to be_nil
        expect(json['website']).to eq(other_user.website)
        expect(json['zip']).to be_nil
        expect(json['overlap']).to eq('none')
      end
    end
  end

  describe 'headshot_url and resume_url visibility' do
    let(:fake_presigner) { instance_double(Aws::S3::Presigner, presigned_url: 'https://s3.example.com/fake-signed-url') }

    before do
      allow(Aws::S3::Client).to receive(:new).and_return(instance_double(Aws::S3::Client))
      allow(Aws::S3::Presigner).to receive(:new).and_return(fake_presigner)
      user.update!(headshot_url: 'headshots/1/abc.png', resume_url: 'resumes/1/abc.pdf')
    end

    shared_examples 'exposes headshot and resume' do
      it 'includes headshot_url' do
        expect(json['headshot_url']).to eq('https://s3.example.com/fake-signed-url')
      end

      it 'includes resume_url' do
        expect(json['resume_url']).to eq('https://s3.example.com/fake-signed-url')
      end
    end

    shared_examples 'exposes headshot but not resume' do
      it 'includes headshot_url' do
        expect(json['headshot_url']).to eq('https://s3.example.com/fake-signed-url')
      end

      it 'omits resume_url' do
        expect(json['resume_url']).to be_nil
      end
    end

    context 'when viewer is self' do
      before { get "/api/v1/users/#{user.id}/", headers: authenticated_header(user) }
      include_examples 'exposes headshot and resume'
    end

    context 'when viewer is a superadmin' do
      let!(:super_user) { create(:user, role: 'superadmin') }
      before { get "/api/v1/users/#{user.id}/", headers: authenticated_header(super_user) }
      include_examples 'exposes headshot and resume'
    end

    context 'when viewer is a theater admin over the user' do
      let!(:local_theater) { create(:theater) }
      let!(:admin_user) { create(:user, :paid) }

      before do
        create(:job, :admin_job, user: admin_user, theater: local_theater, end_date: nil)
        create(:job, user: user, theater: local_theater, end_date: nil)
        get "/api/v1/users/#{user.id}/", headers: authenticated_header(admin_user)
      end

      include_examples 'exposes headshot and resume'
    end

    context 'when viewer is a production admin over the user' do
      let!(:local_theater) { create(:theater) }
      let!(:local_production) { create(:production, theater: local_theater) }
      let!(:director_spec) { create(:specialization, :director) }
      let!(:admin_user) { create(:user, :paid) }

      before do
        create(:job, user: admin_user, theater: local_theater, production: local_production, specialization: director_spec, end_date: nil)
        create(:job, user: user, theater: local_theater, production: local_production, end_date: nil)
        get "/api/v1/users/#{user.id}/", headers: authenticated_header(admin_user)
      end

      include_examples 'exposes headshot and resume'
    end

    context 'when viewer is a production peer (non-admin)' do
      let!(:local_theater) { create(:theater) }
      let!(:local_production) { create(:production, theater: local_theater) }
      let!(:peer) { create(:user) }

      before do
        create(:job, :actor_job, user: peer, theater: local_theater, production: local_production, end_date: nil)
        create(:job, user: user, theater: local_theater, production: local_production, end_date: nil)
        get "/api/v1/users/#{user.id}/", headers: authenticated_header(peer)
      end

      include_examples 'exposes headshot but not resume'
    end

    context 'when viewer is a theater peer (non-admin)' do
      let!(:local_theater) { create(:theater) }
      let!(:peer) { create(:user) }

      before do
        create(:job, user: peer, theater: local_theater, end_date: nil)
        create(:job, user: user, theater: local_theater, end_date: nil)
        get "/api/v1/users/#{user.id}/", headers: authenticated_header(peer)
      end

      include_examples 'exposes headshot but not resume'
    end

    context 'when viewer has no relationship to the user' do
      let!(:stranger) { create(:user) }
      before { get "/api/v1/users/#{user.id}/", headers: authenticated_header(stranger) }
      include_examples 'exposes headshot but not resume'
    end
  end

  describe 'PUT /api/v1/users/:user_id/upload_headshot' do
    let(:fake_s3_client) { instance_double(Aws::S3::Client, put_object: true) }
    let(:fake_presigner) { instance_double(Aws::S3::Presigner, presigned_url: 'https://s3.example.com/fake-signed-url') }

    before do
      allow(Aws::S3::Client).to receive(:new).and_return(fake_s3_client)
      allow(Aws::S3::Presigner).to receive(:new).and_return(fake_presigner)
    end

    def png_upload(filename: 'headshot.png')
      uploaded_file(valid_png_bytes, content_type: 'image/png', filename: filename)
    end

    it 'uploads a valid image and stores the S3 key on the user' do
      put "/api/v1/users/#{user.id}/upload_headshot", params: { headshot: png_upload }, headers: authenticated_header(user)
      expect(response).to have_http_status(200)
      expect(json['headshot_url']).to eq('https://s3.example.com/fake-signed-url')
      expect(user.reload.headshot_url).to match(%r{\Aheadshots/#{user.id}/.+\.png\z})
    end

    it 'sends the file contents to S3 with the detected content type' do
      expect(fake_s3_client).to receive(:put_object).with(hash_including(content_type: 'image/png'))
      put "/api/v1/users/#{user.id}/upload_headshot", params: { headshot: png_upload }, headers: authenticated_header(user)
    end

    it 'rejects a file that is not an allowed image type' do
      file = uploaded_file(valid_pdf_bytes, content_type: 'image/png', filename: 'fake.png')
      put "/api/v1/users/#{user.id}/upload_headshot", params: { headshot: file }, headers: authenticated_header(user)
      expect(response).to have_http_status(422)
      expect(json['error']).to match(/JPEG, PNG, GIF, and WebP/)
      expect(user.reload.headshot_url).to be_nil
    end

    it 'rejects a file over 5MB' do
      oversized = valid_png_bytes + ('0' * 6.megabytes)
      file = uploaded_file(oversized, content_type: 'image/png', filename: 'big.png')
      put "/api/v1/users/#{user.id}/upload_headshot", params: { headshot: file }, headers: authenticated_header(user)
      expect(response).to have_http_status(422)
      expect(json['error']).to match(/smaller than 5 MB/)
      expect(user.reload.headshot_url).to be_nil
    end

    it 'requires a file' do
      put "/api/v1/users/#{user.id}/upload_headshot", params: {}, headers: authenticated_header(user)
      expect(response).to have_http_status(422)
      expect(json['error']).to eq('No file provided')
    end

    it 'does not allow uploading a headshot for another user' do
      other_user = create(:user)
      put "/api/v1/users/#{other_user.id}/upload_headshot", params: { headshot: png_upload }, headers: authenticated_header(user)
      expect(response).to have_http_status(403)
      expect(other_user.reload.headshot_url).to be_nil
    end
  end

  describe 'PUT /api/v1/users/:user_id/upload_resume' do
    let(:fake_s3_client) { instance_double(Aws::S3::Client, put_object: true) }
    let(:fake_presigner) { instance_double(Aws::S3::Presigner, presigned_url: 'https://s3.example.com/fake-signed-url') }

    before do
      allow(Aws::S3::Client).to receive(:new).and_return(fake_s3_client)
      allow(Aws::S3::Presigner).to receive(:new).and_return(fake_presigner)
    end

    def pdf_upload(filename: 'resume.pdf')
      uploaded_file(valid_pdf_bytes, content_type: 'application/pdf', filename: filename)
    end

    it 'uploads a valid resume and stores the S3 key on the user' do
      put "/api/v1/users/#{user.id}/upload_resume", params: { resume: pdf_upload }, headers: authenticated_header(user)
      expect(response).to have_http_status(200)
      expect(json['resume_url']).to eq('https://s3.example.com/fake-signed-url')
      expect(user.reload.resume_url).to match(%r{\Aresumes/#{user.id}/.+\.pdf\z})
    end

    it 'sends the file contents to S3 with the detected content type' do
      expect(fake_s3_client).to receive(:put_object).with(hash_including(content_type: 'application/pdf'))
      put "/api/v1/users/#{user.id}/upload_resume", params: { resume: pdf_upload }, headers: authenticated_header(user)
    end

    it 'rejects a file that is not an allowed resume type' do
      file = uploaded_file(valid_png_bytes, content_type: 'application/pdf', filename: 'fake.pdf')
      put "/api/v1/users/#{user.id}/upload_resume", params: { resume: file }, headers: authenticated_header(user)
      expect(response).to have_http_status(422)
      expect(json['error']).to match(/PDF, DOC, and DOCX/)
      expect(user.reload.resume_url).to be_nil
    end

    it 'rejects a file over 5MB' do
      oversized = valid_pdf_bytes + ('0' * 6.megabytes)
      file = uploaded_file(oversized, content_type: 'application/pdf', filename: 'big.pdf')
      put "/api/v1/users/#{user.id}/upload_resume", params: { resume: file }, headers: authenticated_header(user)
      expect(response).to have_http_status(422)
      expect(json['error']).to match(/smaller than 5 MB/)
      expect(user.reload.resume_url).to be_nil
    end

    it 'requires a file' do
      put "/api/v1/users/#{user.id}/upload_resume", params: {}, headers: authenticated_header(user)
      expect(response).to have_http_status(422)
      expect(json['error']).to eq('No file provided')
    end

    it 'does not allow uploading a resume for another user' do
      other_user = create(:user)
      put "/api/v1/users/#{other_user.id}/upload_resume", params: { resume: pdf_upload }, headers: authenticated_header(user)
      expect(response).to have_http_status(403)
      expect(other_user.reload.resume_url).to be_nil
    end
  end

  describe 'POST /api/v1/users' do
    let(:valid_params) do
      { user: { first_name: 'Jane', last_name: 'Doe', email: 'jane.doe@example.com' } }
    end

    it 'creates a user with minimum required fields and returns 201' do
      post '/api/v1/users', params: valid_params, as: :json
      expect(response).to have_http_status(201)
      expect(json['first_name']).to eq('Jane')
      expect(json['last_name']).to eq('Doe')
      expect(json['email']).to eq('jane.doe@example.com')
    end

    it 'creates a user without a phone number' do
      post '/api/v1/users', params: valid_params, as: :json
      expect(response).to have_http_status(201)
      expect(json['id']).to be_present
    end

    it 'does not enqueue MakeFakeTheaterWorker for admin-created users' do
      MakeFakeTheaterWorker.clear
      post '/api/v1/users', params: valid_params, as: :json
      expect(MakeFakeTheaterWorker.jobs.size).to eq(0)
    end

    it 'returns 422 when first_name is missing' do
      post '/api/v1/users', params: { user: { last_name: 'Doe', email: 'x@example.com' } }, as: :json
      expect(response).to have_http_status(422)
    end

    it 'returns 422 when last_name is missing' do
      post '/api/v1/users', params: { user: { first_name: 'Jane', email: 'x@example.com' } }, as: :json
      expect(response).to have_http_status(422)
    end

    it 'returns 422 when email is missing' do
      post '/api/v1/users', params: { user: { first_name: 'Jane', last_name: 'Doe' } }, as: :json
      expect(response).to have_http_status(422)
    end

    it 'returns 422 when email is already taken' do
      post '/api/v1/users', params: valid_params, as: :json
      post '/api/v1/users', params: valid_params, as: :json
      expect(response).to have_http_status(422)
    end

    it 'does not require authentication' do
      post '/api/v1/users', params: valid_params, as: :json
      expect(response).not_to have_http_status(401)
    end
  end

  describe 'GET /api/v1/users/fake' do
    let!(:fake_user) { create(:user, fake: true, provider: 'fake', gender: 'cis female') }

    it 'returns status 200' do
      get '/api/v1/users/fake', headers: authenticated_header(user)
      expect(response).to have_http_status(200)
    end

    it 'returns only fake users' do
      get '/api/v1/users/fake', headers: authenticated_header(user)
      ids = json.map { |u| u['id'] }
      expect(ids).to include(fake_user.id)
      expect(ids).not_to include(user.id)
    end

    it 'includes jobs in the response' do
      get '/api/v1/users/fake', headers: authenticated_header(user)
      expect(json.first).to have_key('jobs')
    end
  end

  describe 'POST /api/v1/users/generate_fake' do
    it 'returns status 201' do
      post '/api/v1/users/generate_fake', params: { gender: 'cis female' }, as: :json, headers: authenticated_header(user)
      expect(response).to have_http_status(201)
    end

    it 'creates a fake user with the given gender' do
      post '/api/v1/users/generate_fake', params: { gender: 'cis male' }, as: :json, headers: authenticated_header(user)
      expect(json['gender']).to eq('cis male')
      expect(json['fake']).to be true
    end

    it 'creates a user with a fake.example email' do
      post '/api/v1/users/generate_fake', params: { gender: 'cis female' }, as: :json, headers: authenticated_header(user)
      expect(json['email']).to end_with('@fake.example')
    end

    it 'defaults to cis female when no gender is provided' do
      post '/api/v1/users/generate_fake', as: :json, headers: authenticated_header(user)
      expect(json['gender']).to eq('cis female')
    end

    it 'persists the new fake user in the database' do
      expect {
        post '/api/v1/users/generate_fake', params: { gender: 'nonbinary' }, as: :json, headers: authenticated_header(user)
      }.to change { User.where(fake: true).count }.by(1)
    end
  end

  describe 'put /api/users/:user_id/build_conflict_schedule' do
    before {
      conflict_schedule_pattern = {
          "category": "work",
          "days_of_week": ['Monday', 'Wednesday'],
          "end_date": "2020-03-20",
          "end_time": "17:00:00",
          "user_id": user.id,
          "space_id": space.id,
          "start_date": "2020-02-20",
          "start_time": "12:00:00"}
      put "/api/v1/users/#{user.id}/build_conflict_schedule", as: :json, params: {conflict_schedule_pattern: conflict_schedule_pattern}, headers: authenticated_header(user)
    }
    it 'returns 200' do
      expect(response).to have_http_status(200)
    end
    it 'starts production build worker' do
      expect(BuildConflictsScheduleWorker.jobs.size).to eql(1)
      BuildConflictsScheduleWorker.drain
      expect(BuildConflictsScheduleWorker.jobs.size).to eql(0)
      expect(Conflict.all.size).to eq(13)
      expect(Conflict.all.first.user.id).to eq(user.id)
    end
  end
end
