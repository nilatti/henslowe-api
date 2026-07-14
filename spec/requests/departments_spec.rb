require 'rails_helper'

RSpec.describe 'Departments API', type: :request do
  let!(:user) { create(:user, role: 'superadmin') }
  let!(:departments) { create_list(:department, 4) }
  let(:department_id) { departments.first.id }

  describe 'GET /departments' do
    before { get '/api/v1/departments', headers: authenticated_header(user) }

    it 'returns departments' do
      expect(json).not_to be_empty
      expect(json.size).to eq(4)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET api/departments/:id' do
    before { get "/api/v1/departments/#{department_id}", headers: authenticated_header(user) }

    context 'when the record exists' do
      it 'returns the department' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(department_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'includes nested specializations' do
        expect(json).to have_key('specializations')
      end
    end

    context 'when the record does not exist' do
      let(:department_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'POST /departments' do
    let(:valid_attributes) { { department: { name: 'Costumes' } } }

    context 'when the request is valid' do
      before { post '/api/v1/departments', params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'creates a department' do
        expect(json['name']).to eq('Costumes')
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      before { post '/api/v1/departments', params: { department: { name: '' } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end
    end
  end

  describe 'PUT /departments/:id' do
    let(:valid_attributes) { { department: { name: 'Lighting' } } }

    before { put "/api/v1/departments/#{department_id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end

    it 'persists the update' do
      expect(Department.find(department_id).name).to eq('Lighting')
    end
  end

  describe 'DELETE /departments/:id' do
    before { delete "/api/v1/departments/#{department_id}", headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

  describe 'linking specializations' do
    it 'nests the department on a specialization response' do
      department = departments.first
      specialization = create(:specialization, department: department)
      get "/api/v1/specializations/#{specialization.id}", headers: authenticated_header(user)
      expect(json['department']['id']).to eq(department.id)
    end
  end
end
