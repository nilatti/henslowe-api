# spec/requests/productions_spec.rb
require 'rails_helper'

RSpec.describe 'Users API' do
  # Initialize the test data
  let!(:user) { create(:user) }
  let!(:jobs) {create_list(:job, 3, user: user)}
  let!(:conflicts) {create_list(:conflict, 5, user: user)}
  let!(:users) {create_list(:user, 10)}
  let!(:id) { user.id }
  let!(:space) {create(:space)}
  # Test suite for GET /productions/:production_id/rehearsals
  describe 'GET api/users' do
    before {
      get "/api/users/", headers: authenticated_header(user)
    }

    context 'when users exist' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all users' do
        expect(json.size).to eq(11)
      end
    end
  end

  # Test suite for GET /users/:user_id/
  describe 'GET /users/:user_id/' do
    before { get "/api/users/#{id}/", headers: authenticated_header(user) }

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
  describe 'access user data' do
    # all logged in users should be able to see preferred name, last name, basic contact info, jobs
    #the current_user's relationship to the target user is determined in user#jobs_overlap and is tested in users_controller#show
    context 'when user is self' do
      before {
        login_user(user)
        get "/api/users/#{id}/", headers: authenticated_header(user)
      }
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all user information' do
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
      end
    end
    # super user should be able to see all info for other users
    context 'when user is super user' do
      let!(:super_user) { create(:user, role: "superadmin") }
      before {
        login_user(super_user)
        get "/api/users/#{id}/", headers: authenticated_header(super_user)
      }
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all user information' do
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
      end
    end
    # theater admin should be able to see all info for users who are *currently* or *formerly* employed at theater, but not for other users
    context 'when user is theater admin' do
      let!(:local_theater) { create(:theater)}
      let!(:theater_admin_user) { create(:user) }
      let!(:theater_admin_job) {create(:job, :admin_job, user: theater_admin_user, theater: local_theater)}
      it 'returns all user information for user who works at theater' do
        login_user(theater_admin_user)
        user_who_works_at_theater = create(:user)
        user_at_theater_job = create(:job, user: user_who_works_at_theater, theater: local_theater)
        get "/api/users/#{user_who_works_at_theater.id}/", headers: authenticated_header(theater_admin_user)
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
      end
      it "returns basic information for a user who doesn't have any jobs" do
        login_user(theater_admin_user)
        other_theater_user_without_jobs = create(:user)
        get "/api/users/#{other_theater_user_without_jobs.id}/", headers: authenticated_header(theater_admin_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_theater_user_without_jobs.bio)
        expect(json['city']).to eq(other_theater_user_without_jobs.city)
        expect(json['description']).to eq(other_theater_user_without_jobs.description)
        expect(json['email']).to eq(other_theater_user_without_jobs.email)
        expect(json['first_name']).to eq(other_theater_user_without_jobs.first_name)
        expect(json['gender']).to eq(other_theater_user_without_jobs.gender)
        expect(json['id']).to eq(other_theater_user_without_jobs.id)
        expect(json['last_name']).to eq(other_theater_user_without_jobs.last_name)
        expect(json['program_name']).to eq(other_theater_user_without_jobs.program_name)
        expect(json['preferred_name']).to eq(other_theater_user_without_jobs.preferred_name)
        expect(json['state']).to eq(other_theater_user_without_jobs.state)
        expect(json['website']).to eq(other_theater_user_without_jobs.website)
      end
      it "blocks a request for a user who only has jobs at other theaters" do
        other_theater_user_with_jobs = create(:user)
        other_theater = create(:theater)
        create_list(:job, 3, user: other_theater_user_with_jobs, theater: other_theater)
        login_user(theater_admin_user)
        get "/api/users/#{other_theater_user_with_jobs.id}/", headers: authenticated_header(theater_admin_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_theater_user_with_jobs.bio)
        expect(json['city']).to eq(other_theater_user_with_jobs.city)
        expect(json['description']).to eq(other_theater_user_with_jobs.description)
        expect(json['email']).to eq(other_theater_user_with_jobs.email)
        expect(json['first_name']).to eq(other_theater_user_with_jobs.first_name)
        expect(json['gender']).to eq(other_theater_user_with_jobs.gender)
        expect(json['id']).to eq(other_theater_user_with_jobs.id)
        expect(json['last_name']).to eq(other_theater_user_with_jobs.last_name)
        expect(json['program_name']).to eq(other_theater_user_with_jobs.program_name)
        expect(json['preferred_name']).to eq(other_theater_user_with_jobs.preferred_name)
        expect(json['state']).to eq(other_theater_user_with_jobs.state)
        expect(json['website']).to eq(other_theater_user_with_jobs.website)
      end
      it "returns minimal info on a user who worked here in the past" do
        past_theater_employee_user = create(:user)
        past_theater_job = create(:job, start_date: Date.today - 9.years, end_date: Date.today - 8.years, theater: local_theater, user: past_theater_employee_user)
        login_user(theater_admin_user)
        get "/api/users/#{past_theater_employee_user.id}/", headers: authenticated_header(theater_admin_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(past_theater_employee_user.bio)
        expect(json['city']).to eq(past_theater_employee_user.city)
        expect(json['description']).to eq(past_theater_employee_user.description)
        expect(json['email']).to eq(past_theater_employee_user.email)
        expect(json['first_name']).to eq(past_theater_employee_user.first_name)
        expect(json['gender']).to eq(past_theater_employee_user.gender)
        expect(json['id']).to eq(past_theater_employee_user.id)
        expect(json['jobs'].size).to eq(past_theater_employee_user.jobs.size)
        expect(json['last_name']).to eq(past_theater_employee_user.last_name)
        expect(json['program_name']).to eq(past_theater_employee_user.program_name)
        expect(json['preferred_name']).to eq(past_theater_employee_user.preferred_name)
        expect(json['state']).to eq(past_theater_employee_user.state)
        expect(json['website']).to eq(past_theater_employee_user.website)
      end
    end
    # production admin should be able to see all info for users who are *currently* working on production
    context 'when user is production admin' do
      let!(:local_theater) { create(:theater)}
      let!(:local_production) {create(:production)}
      let!(:production_admin_user) { create(:user) }
      let!(:production_admin_job) {create(:job, :admin_job, user: production_admin_user, theater: local_theater, production: local_production)}
      it 'returns all user information for user in show' do
        login_user(production_admin_user)
        user_who_works_on_production = create(:user)
        user_on_production_job = create(:job, user: user_who_works_on_production, theater: local_theater, production: local_production)
        get "/api/users/#{user_who_works_on_production.id}/", headers: authenticated_header(production_admin_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(user_who_works_on_production.bio)
        expect(Date.parse(json['birthdate'])).to eq(user_who_works_on_production.birthdate)
        expect(json['city']).to eq(user_who_works_on_production.city)
        expect(json['conflicts'].size).to eq(user_who_works_on_production.conflicts.size)
        expect(json['description']).to eq(user_who_works_on_production.description)
        expect(json['email']).to eq(user_who_works_on_production.email)
        expect(json['emergency_contact_name']).to eq(user_who_works_on_production.emergency_contact_name)
        expect(json['emergency_contact_number']).to eq(user_who_works_on_production.emergency_contact_number)
        expect(json['first_name']).to eq(user_who_works_on_production.first_name)
        expect(json['gender']).to eq(user_who_works_on_production.gender)
        expect(json['id']).to eq(user_who_works_on_production.id)
        expect(json['jobs'].size).to eq(user_who_works_on_production.jobs.size)
        expect(json['last_name']).to eq(user_who_works_on_production.last_name)
        expect(json['middle_name']).to eq(user_who_works_on_production.middle_name)
        expect(json['phone_number']).to eq(user_who_works_on_production.phone_number)
        expect(json['program_name']).to eq(user_who_works_on_production.program_name)
        expect(json['preferred_name']).to eq(user_who_works_on_production.preferred_name)
        expect(json['state']).to eq(user_who_works_on_production.state)
        expect(json['street_address']).to eq(user_who_works_on_production.street_address)
        expect(json['timezone']).to eq(user_who_works_on_production.timezone)
        expect(json['website']).to eq(user_who_works_on_production.website)
        expect(json['zip']).to eq(user_who_works_on_production.zip)
      end
      it "returns basic information for a user who doesn't have any jobs" do
        login_user(production_admin_user)
        other_theater_user_without_jobs = create(:user)
        get "/api/users/#{other_theater_user_without_jobs.id}/", headers: authenticated_header(production_admin_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_theater_user_without_jobs.bio)
        expect(json['city']).to eq(other_theater_user_without_jobs.city)
        expect(json['description']).to eq(other_theater_user_without_jobs.description)
        expect(json['email']).to eq(other_theater_user_without_jobs.email)
        expect(json['first_name']).to eq(other_theater_user_without_jobs.first_name)
        expect(json['gender']).to eq(other_theater_user_without_jobs.gender)
        expect(json['id']).to eq(other_theater_user_without_jobs.id)
        expect(json['last_name']).to eq(other_theater_user_without_jobs.last_name)
        expect(json['program_name']).to eq(other_theater_user_without_jobs.program_name)
        expect(json['preferred_name']).to eq(other_theater_user_without_jobs.preferred_name)
        expect(json['state']).to eq(other_theater_user_without_jobs.state)
        expect(json['website']).to eq(other_theater_user_without_jobs.website)
      end
      it "blocks a request for a user who only has jobs at other theaters" do
        other_theater_user_with_jobs = create(:user)
        other_theater = create(:theater)
        create_list(:job, 3, user: other_theater_user_with_jobs, theater: other_theater)
        login_user(production_admin_user)
        get "/api/users/#{other_theater_user_with_jobs.id}/", headers: authenticated_header(production_admin_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_theater_user_with_jobs.bio)
        expect(json['city']).to eq(other_theater_user_with_jobs.city)
        expect(json['description']).to eq(other_theater_user_with_jobs.description)
        expect(json['email']).to eq(other_theater_user_with_jobs.email)
        expect(json['first_name']).to eq(other_theater_user_with_jobs.first_name)
        expect(json['gender']).to eq(other_theater_user_with_jobs.gender)
        expect(json['id']).to eq(other_theater_user_with_jobs.id)
        expect(json['last_name']).to eq(other_theater_user_with_jobs.last_name)
        expect(json['program_name']).to eq(other_theater_user_with_jobs.program_name)
        expect(json['preferred_name']).to eq(other_theater_user_with_jobs.preferred_name)
        expect(json['state']).to eq(other_theater_user_with_jobs.state)
        expect(json['website']).to eq(other_theater_user_with_jobs.website)
      end
      it "returns minimal info on a user who worked here in the past" do
        past_theater_employee_user = create(:user)
        past_theater_job = create(:job, start_date: Date.today - 9.years, end_date: Date.today - 8.years, theater: local_theater, user: past_theater_employee_user, production: local_production)
        login_user(production_admin_user)
        get "/api/users/#{past_theater_employee_user.id}/", headers: authenticated_header(production_admin_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(past_theater_employee_user.bio)
        expect(json['city']).to eq(past_theater_employee_user.city)
        expect(json['description']).to eq(past_theater_employee_user.description)
        expect(json['email']).to eq(past_theater_employee_user.email)
        expect(json['first_name']).to eq(past_theater_employee_user.first_name)
        expect(json['gender']).to eq(past_theater_employee_user.gender)
        expect(json['id']).to eq(past_theater_employee_user.id)
        expect(json['jobs'].size).to eq(past_theater_employee_user.jobs.size)
        expect(json['last_name']).to eq(past_theater_employee_user.last_name)
        expect(json['program_name']).to eq(past_theater_employee_user.program_name)
        expect(json['preferred_name']).to eq(past_theater_employee_user.preferred_name)
        expect(json['state']).to eq(past_theater_employee_user.state)
        expect(json['website']).to eq(past_theater_employee_user.website)
      end
    end
    # production workers should be able to see most info for users who are *currently* employed on a production that they are also on
    context 'when user is production peer' do
      let!(:local_theater) { create(:theater)}
      let!(:local_production) {create(:production)}
      let!(:production_user) { create(:user) }
      let!(:production_job) {create(:job, :actor_job, user: production_user, theater: local_theater, production: local_production)}
      it 'returns all user information for user in show' do
        login_user(production_user)
        production_peer = create(:user)
        production_peer_job = create(:job, user: production_peer, theater: local_theater, production: local_production)
        get "/api/users/#{production_peer.id}/", headers: authenticated_header(production_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(production_peer.bio)
        expect(json['birthdate']).to be_nil
        expect(json['city']).to eq(production_peer.city)
        expect(json['conflicts'].size).to eq(production_peer.conflicts.size)
        expect(json['description']).to eq(production_peer.description)
        expect(json['email']).to eq(production_peer.email)
        expect(json['emergency_contact_name']).to eq(production_peer.emergency_contact_name)
        expect(json['emergency_contact_number']).to eq(production_peer.emergency_contact_number)
        expect(json['first_name']).to eq(production_peer.first_name)
        expect(json['gender']).to eq(production_peer.gender)
        expect(json['id']).to eq(production_peer.id)
        expect(json['jobs'].size).to eq(production_peer.jobs.size)
        expect(json['last_name']).to eq(production_peer.last_name)
        expect(json['middle_name']).to be_nil
        expect(json['phone_number']).to eq(production_peer.phone_number)
        expect(json['program_name']).to eq(production_peer.program_name)
        expect(json['preferred_name']).to eq(production_peer.preferred_name)
        expect(json['state']).to eq(production_peer.state)
        expect(json['street_address']).to eq(production_peer.street_address)
        expect(json['timezone']).to eq(production_peer.timezone)
        expect(json['website']).to eq(production_peer.website)
        expect(json['zip']).to eq(production_peer.zip)
      end
      it "returns basic information for a user who doesn't have any jobs" do
        login_user(production_user)
        other_theater_user_without_jobs = create(:user)
        get "/api/users/#{other_theater_user_without_jobs.id}/", headers: authenticated_header(production_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_theater_user_without_jobs.bio)
        expect(json['birthdate']).to be_nil
        expect(json['city']).to eq(other_theater_user_without_jobs.city)
        expect(json['conflicts']).to be_nil
        expect(json['description']).to eq(other_theater_user_without_jobs.description)
        expect(json['email']).to eq(other_theater_user_without_jobs.email)
        expect(json['emergency_contact_name']).to be_nil
        expect(json['emergency_contact_number']).to be_nil
        expect(json['first_name']).to eq(other_theater_user_without_jobs.first_name)
        expect(json['gender']).to eq(other_theater_user_without_jobs.gender)
        expect(json['id']).to eq(other_theater_user_without_jobs.id)
        expect(json['jobs']).to be_nil
        expect(json['last_name']).to eq(other_theater_user_without_jobs.last_name)
        expect(json['middle_name']).to be_nil
        expect(json['phone_number']).to be_nil
        expect(json['program_name']).to eq(other_theater_user_without_jobs.program_name)
        expect(json['preferred_name']).to eq(other_theater_user_without_jobs.preferred_name)
        expect(json['state']).to eq(other_theater_user_without_jobs.state)
        expect(json['street_address']).to be_nil
        expect(json['timezone']).to be_nil
        expect(json['website']).to eq(other_theater_user_without_jobs.website)
      end
      it "blocks a request for a user who only has jobs at other theaters" do
        other_theater_user_with_jobs = create(:user)
        other_theater = create(:theater)
        create_list(:job, 3, user: other_theater_user_with_jobs, theater: other_theater)
        login_user(production_user)
        get "/api/users/#{other_theater_user_with_jobs.id}/", headers: authenticated_header(production_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_theater_user_with_jobs.bio)
        expect(json['city']).to eq(other_theater_user_with_jobs.city)
        expect(json['description']).to eq(other_theater_user_with_jobs.description)
        expect(json['email']).to eq(other_theater_user_with_jobs.email)
        expect(json['first_name']).to eq(other_theater_user_with_jobs.first_name)
        expect(json['gender']).to eq(other_theater_user_with_jobs.gender)
        expect(json['id']).to eq(other_theater_user_with_jobs.id)
        expect(json['last_name']).to eq(other_theater_user_with_jobs.last_name)
        expect(json['program_name']).to eq(other_theater_user_with_jobs.program_name)
        expect(json['preferred_name']).to eq(other_theater_user_with_jobs.preferred_name)
        expect(json['state']).to eq(other_theater_user_with_jobs.state)
        expect(json['website']).to eq(other_theater_user_with_jobs.website)
        expect(json['zip']).to be_nil
      end
    end
    # theater workers should be able to see some info for users who are *currently* employed at theater
    context 'when user is theater peer' do
      let!(:local_theater) { create(:theater)}
      let!(:theater_user) { create(:user) }
      let!(:theater_job) {create(:job, user: theater_user, theater: local_theater)}
      it 'returns all user information for user in show' do
        login_user(theater_user)
        theater_peer = create(:user)
        theater_peer_job = create(:job, user: theater_peer, theater: local_theater)
        get "/api/users/#{theater_peer.id}/", headers: authenticated_header(theater_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(theater_peer.bio)
        expect(json['birthdate']).to be_nil
        expect(json['city']).to eq(theater_peer.city)
        expect(json['conflicts'].size).to eq(theater_peer.conflicts.size)
        expect(json['description']).to eq(theater_peer.description)
        expect(json['email']).to eq(theater_peer.email)
        expect(json['emergency_contact_name']).to be_nil
        expect(json['emergency_contact_number']).to be_nil
        expect(json['first_name']).to eq(theater_peer.first_name)
        expect(json['gender']).to eq(theater_peer.gender)
        expect(json['id']).to eq(theater_peer.id)
        expect(json['jobs'].size).to eq(theater_peer.jobs.size)
        expect(json['last_name']).to eq(theater_peer.last_name)
        expect(json['middle_name']).to be_nil
        expect(json['phone_number']).to eq(theater_peer.phone_number)
        expect(json['program_name']).to eq(theater_peer.program_name)
        expect(json['preferred_name']).to eq(theater_peer.preferred_name)
        expect(json['state']).to eq(theater_peer.state)
        expect(json['street_address']).to eq(theater_peer.street_address)
        expect(json['timezone']).to be_nil
        expect(json['website']).to eq(theater_peer.website)
        expect(json['zip']).to eq(theater_peer.zip)
      end
      it "returns basic information for a user who doesn't have any jobs" do
        login_user(theater_user)
        other_theater_user_without_jobs = create(:user)
        get "/api/users/#{other_theater_user_without_jobs.id}/", headers: authenticated_header(theater_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_theater_user_without_jobs.bio)
        expect(json['birthdate']).to be_nil
        expect(json['city']).to eq(other_theater_user_without_jobs.city)
        expect(json['conflicts']).to be_nil
        expect(json['description']).to eq(other_theater_user_without_jobs.description)
        expect(json['email']).to eq(other_theater_user_without_jobs.email)
        expect(json['emergency_contact_name']).to be_nil
        expect(json['emergency_contact_number']).to be_nil
        expect(json['first_name']).to eq(other_theater_user_without_jobs.first_name)
        expect(json['gender']).to eq(other_theater_user_without_jobs.gender)
        expect(json['id']).to eq(other_theater_user_without_jobs.id)
        expect(json['jobs']).to be_nil
        expect(json['last_name']).to eq(other_theater_user_without_jobs.last_name)
        expect(json['middle_name']).to be_nil
        expect(json['phone_number']).to be_nil
        expect(json['program_name']).to eq(other_theater_user_without_jobs.program_name)
        expect(json['preferred_name']).to eq(other_theater_user_without_jobs.preferred_name)
        expect(json['state']).to eq(other_theater_user_without_jobs.state)
        expect(json['street_address']).to be_nil
        expect(json['timezone']).to be_nil
        expect(json['website']).to eq(other_theater_user_without_jobs.website)
      end
      it "blocks a request for a user who only has jobs at other theaters" do
        other_theater_user_with_jobs = create(:user)
        other_theater = create(:theater)
        create_list(:job, 3, user: other_theater_user_with_jobs, theater: other_theater)
        login_user(theater_user)
        get "/api/users/#{other_theater_user_with_jobs.id}/", headers: authenticated_header(theater_user)
        expect(response).to have_http_status(200)
        expect(json['bio']).to eq(other_theater_user_with_jobs.bio)
        expect(json['city']).to eq(other_theater_user_with_jobs.city)
        expect(json['description']).to eq(other_theater_user_with_jobs.description)
        expect(json['email']).to eq(other_theater_user_with_jobs.email)
        expect(json['first_name']).to eq(other_theater_user_with_jobs.first_name)
        expect(json['gender']).to eq(other_theater_user_with_jobs.gender)
        expect(json['id']).to eq(other_theater_user_with_jobs.id)
        expect(json['last_name']).to eq(other_theater_user_with_jobs.last_name)
        expect(json['program_name']).to eq(other_theater_user_with_jobs.program_name)
        expect(json['preferred_name']).to eq(other_theater_user_with_jobs.preferred_name)
        expect(json['state']).to eq(other_theater_user_with_jobs.state)
        expect(json['website']).to eq(other_theater_user_with_jobs.website)
        expect(json['zip']).to be_nil
      end
    end
    # eventually some users should be able to access specific private info like costume designer should be able to access measurements for people on CURRENT producitons
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
      put "/api/users/#{user.id}/build_conflict_schedule", as: :json, params: {conflict_schedule_pattern: conflict_schedule_pattern}, headers: authenticated_header(user)
    }
    it 'returns 200' do
      expect(response).to have_http_status(200)
    end
    it 'starts production build worker' do
      expect(BuildConflictsScheduleWorker.jobs.size).to eql(1)
      BuildConflictsScheduleWorker.drain
      expect(BuildConflictsScheduleWorker.jobs.size).to eql(0)
      expect(Conflict.all.size).to eq(8)
      expect(Conflict.all.first.user.id).to eq(user.id)
    end
  end

end
