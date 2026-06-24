require 'rails_helper'

RSpec.describe 'jobs API', type: :request do
  # initialize test data

  let!(:user) { create(:user)}
  let!(:jobs) { create_list(:job, 8, user: user) }
  let!(:job_id) { jobs.first.id }
  let!(:production) { create(:production)}
  let!(:theater) {create(:theater)}
  let!(:admin_theater) { create(:theater) }
  let!(:admin_user) { create(:user) }
  let!(:theater_admin_job) { create(:job, user: admin_user, theater: admin_theater, specialization: create(:specialization, :theater_admin)) }

  # Test suite for GET /jobs
  describe 'GET /jobs' do
    # make HTTP get request before each example
    before { get '/api/v1/jobs', as: :json, headers: authenticated_header(user) }

    it 'returns jobs' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json).not_to be_empty
      expect(json.size).to eq(8)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /jobs/:id
  describe 'GET api/jobs/:id' do
    before { get "/api/v1/jobs/#{job_id}", as: :json, headers: authenticated_header(user) }
    context 'when the record exists' do
      it 'returns the job' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(job_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:job_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Job/)
      end
    end
  end

  # Test suite for POST /jobs
  describe 'POST /jobs' do
    # valid payload

    context 'when the request is valid' do

      it 'creates a job' do
        test_job = build(:job)
        valid_attributes = {
          job: {
            end_date: test_job.end_date,
            specialization_id: test_job.specialization.id,
            start_date: test_job.start_date,
            theater_id: admin_theater.id,
            user_id: test_job.user.id,
          } }
        post '/api/v1/jobs', params: valid_attributes, as: :json, headers: authenticated_header(admin_user)
        expect(json['user_id']).to eq(test_job.user.id)
      end

      it 'creates a job, without an end date' do
        test_job = build(:job)
        valid_attributes = { job:
          {
            user_id: test_job.user.id,
            specialization_id: test_job.specialization.id,
            start_date: test_job.start_date,
            theater_id: admin_theater.id,
          }
        }
        post '/api/v1/jobs', params: valid_attributes, as: :json, headers: authenticated_header(admin_user)
        expect(response).to have_http_status(201)
      end

      it 'creates a job, without any dates' do
        test_job = build(:job)
        valid_attributes = { job:
          {
            user_id: test_job.user.id,
            specialization_id: test_job.specialization.id,
            theater_id: admin_theater.id,
          }
        }
        post '/api/v1/jobs', params: valid_attributes, as: :json, headers: authenticated_header(admin_user)
        expect(response).to have_http_status(201)
      end
    end

    context 'when the user is creating an auditioner job for themselves' do
      it 'returns status 201' do
        auditioner = create(:specialization, :auditioner)
        post '/api/v1/jobs', params: {
          job: { user_id: user.id, specialization_id: auditioner.id }
        }, as: :json, headers: authenticated_header(user)
        expect(response).to have_http_status(201)
      end

      it 'returns 403 when creating an auditioner job for someone else' do
        other_user = create(:user)
        auditioner = create(:specialization, :auditioner)
        post '/api/v1/jobs', params: {
          job: { user_id: other_user.id, specialization_id: auditioner.id }
        }, as: :json, headers: authenticated_header(user)
        expect(response).to have_http_status(403)
      end

      it 'returns 403 when creating a non-auditioner job for themselves' do
        post '/api/v1/jobs', params: {
          job: { user_id: user.id, specialization_id: create(:specialization, :actor).id }
        }, as: :json, headers: authenticated_header(user)
        expect(response).to have_http_status(403)
      end
    end

    context 'when the request is invalid' do
      before { post '/api/v1/jobs', params: { job: { end_date: '2001-09-01', start_date: '2002-11-01', theater_id: admin_theater.id } }, as: :json, headers: authenticated_header(admin_user) }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(response.body)
          .to match(/can\'t be before start date/)
      end
    end
  end

  # Test suite for PUT /jobs/:id
  describe 'PUT /api/jobs/:id' do

    context 'when the record exists' do

      it 'returns status code 200' do
        test_job = build(:job)
        valid_attributes = {
          job: {
            specialization_id: test_job.specialization.id,
            start_date: test_job.start_date,
            theater_id: test_job.theater.id,
            } }
          put "/api/v1/jobs/#{job_id}", params: valid_attributes, as: :json, headers: authenticated_header(user)
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'character_group_id param' do
    it 'permits character_group_id when creating a job' do
      character_group = create(:character_group)
      test_job = build(:job, :actor_job)
      post '/api/v1/jobs', params: {
        job: {
          character_group_id: character_group.id,
          user_id: test_job.user.id,
          theater_id: admin_theater.id,
          specialization_id: test_job.specialization.id,
        }
      }, as: :json, headers: authenticated_header(admin_user)
      expect(response).to have_http_status(201)
      expect(json['character_group_id']).to eq(character_group.id)
    end
  end

  # Test suite for DELETE /jobs/:id
  describe 'DELETE /jobs/:id' do
    before { delete "/api/v1/jobs/#{job_id}", as: :json, headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

  describe 'get actors for production' do
    before {
      create_list(:job, 2, :actor_job, production: production)
      get '/api/v1/jobs', as: :json, params: { roles: 'Actor', production_id: production.id }, headers: authenticated_header(user)
    }
    it 'returns successfully' do
      expect(response).to have_http_status(200)
    end
    it 'returns all the relevant jobs' do
      expect(json.size).to eq(2)
      job = json[0]
      expect(job['production_id']).to eq(production.id)
      expect(Specialization.find(job['specialization_id']).title).to eq('Actor')
    end
  end

  describe 'get actors and auditioners for production' do

    before {
      create_list(:job, 2, :actor_job, production: production)
      create_list(:job, 3, :auditioner_job, production: production)
      get '/api/v1/jobs', as: :json, params: { roles: 'Actor,Auditioner', production_id: production.id }, headers: authenticated_header(user)
    }
    it 'returns successfully' do
      expect(response).to have_http_status(200)
    end
    it 'returns all the relevant jobs' do
      expect(json.size).to eq(5)
      expect(json[0]['production_id']).to eq(production.id)
      expect(Specialization.find(json[0]['specialization_id']).title).to eq('Actor')
      expect(Specialization.find(json[4]['specialization_id']).title).to eq('Auditioner')
    end
  end


  describe 'gets actors and auditioners for theater' do

    before {
      create_list(:job, 3, :actor_job, theater: theater)
      create_list(:job, 3, :auditioner_job, theater: theater)
      get '/api/v1/jobs', as: :json, params: { roles: 'Actor,Auditioner', theater_id: theater.id }, headers: authenticated_header(user)
    }
    it 'returns successfully' do
      expect(response).to have_http_status(200)
    end
    it 'returns all the relevant jobs' do
      expect(json.size).to eq(6)
      job = json[0]
      expect(job['theater_id']).to eq(theater.id)
      expect(Specialization.find(job['specialization_id']).title).to eq('Actor')
      expect(Specialization.find(json[5]['specialization_id']).title).to eq('Auditioner')
    end
  end

  describe 'GET /jobs includes play id in production' do
    let!(:production_with_play) { create(:production) }
    let!(:job_for_production) { create(:job, production: production_with_play) }

    before {
      get '/api/v1/jobs', as: :json, params: { production_id: production_with_play.id }, headers: authenticated_header(user)
    }

    it 'returns successfully' do
      expect(response).to have_http_status(200)
    end

    it 'includes the play id nested inside the production' do
      expect(json.first['production']['play']['id']).to eq(production_with_play.play.id)
    end
  end
end
