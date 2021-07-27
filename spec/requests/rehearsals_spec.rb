# spec/requests/productions_spec.rb
require 'rails_helper'

RSpec.describe 'Rehearsals API' do
  # Initialize the test data
  let!(:production) { create(:production, start_date: Date.today, end_date: 6.weeks.from_now) }
  let!(:play) { production.play }
  let!(:scenes) { [play.scenes.first]}
  let!(:french_scenes) { scenes.first.french_scenes }
  let!(:excess) {create_list(:rehearsal, 3, scenes: [play.scenes.last], production: production)}
  let!(:acts) { [production.play.acts.first, production.play.acts.last]}
  let!(:rehearsals) {create_list(:rehearsal, 3, production: production, scenes: scenes)}
  let!(:id) { rehearsals.first.id }
  let!(:user) { create(:user)}
  let!(:act_rehearsals) {create_list(:rehearsal, 4, acts: acts, production: production)}
  let!(:french_scene_rehearsals){create_list(:rehearsal, 1, french_scenes: french_scenes, production: production)}
  # Test suite for GET /productions/:production_id/rehearsals
  describe 'GET api/productions/:production_id/rehearsals' do
    before {
      get "/api/productions/#{production.id}/rehearsals", headers: authenticated_header(user)
    }

    context 'when production exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all rehearsals' do
        expect(json.size).to eq(11)
      end
    end
  end

  describe 'GET api/productions/:production_id/rehearsals with dates' do
    before {
      get "/api/productions/#{production.id}/rehearsals", params: {start_time: production.start_date, end_time: production.start_date + 1.week}, as: :json, headers: authenticated_header(user)
    }
    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
    it 'does returns all of the rehearsals' do
      expect(json.size).to eq production.rehearsals.size
      expect(json.size).to be > 0
    end

  end

  describe 'GET api/french_scenes/:french_scene_id/rehearsals' do
    before {
      french_scene_id = french_scenes.first.id
      get "/api/french_scenes/#{french_scene_id}/rehearsals", headers: authenticated_header(user)
    }

    context 'when french scene exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all rehearsals only for french scene' do
        expect(json.size).to eq(1)
      end
    end
  end


  describe 'GET api/scenes/:scene_id/rehearsals' do
    before {
      scene_id = scenes.first.id
      get "/api/scenes/#{scene_id}/rehearsals", headers: authenticated_header(user)
    }

    context 'when scene exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all rehearsals only for scene' do
        expect(json.size).to eq(3)
      end
    end
  end

  describe 'GET api/acts/:act_id/rehearsals' do
    before {
      act_id = acts.first.id
      get "/api/acts/#{act_id}/rehearsals", headers: authenticated_header(user)
    }

    context 'when act exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all rehearsals only for act' do
        expect(json.size).to eq(4)
      end
    end
  end

  # Test suite for GET /productions/:production_id/rehearsals/:id
  describe 'GET /productions/:production_id/rehearsals/:id' do
    before { get "/api/productions/#{production.id}/rehearsals/#{id}", headers: authenticated_header(user) }

    context 'when rehearsal exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the rehearsal' do
        expect(json['id']).to eq(id)
      end
    end

    context 'when rehearsal does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Rehearsal/)
      end
    end
  end

  # Test suite for PUT /productions/:production_id/rehearsals
  describe 'POST /productions/:production_id/rehearsals' do
    let(:valid_attributes) { { rehearsal: { name: 'Richard, Duke of Gloucester', production_id: production.id } } }

    context 'when request attributes are valid' do
      before { post "/api/productions/#{production.id}/rehearsals", params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'returns status code 201' do
        expect(response).to have_http_status(200)
      end
    end

    # context 'when an invalid request' do
    #   before { post "/api/productions/#{production.id}/rehearsals", params: { rehearsal: { start_time: Time.now, end_time: Time.now - 4.hours, production_id: production.id } }, as: :json, headers: authenticated_header(user) }
    #
    #   it 'returns status code 422' do
    #     expect(response).to have_http_status(422)
    #   end
    #
    #   it 'returns a failure message' do
    #     expected_response = "{\"name\":[\"can't be blank\"]}"
    #     expect(response.body).to match(expected_response)
    #   end
    # end
  end

  # Test suite for PUT /productions/:production_id/rehearsals/:id
  describe 'PUT /api/productions/:production_id/rehearsals/:id' do
    let(:valid_attributes) { { rehearsal: { title: "Today we rehearse in the tub!" } } }

    before { put "/api/productions/#{production.id}/rehearsals/#{id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

    context 'when rehearsal exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'updates the rehearsal' do
        updated_rehearsal = Rehearsal.find(id)
        expect(updated_rehearsal.title).to match(/Today we rehearse in the tub!/)
      end
    end

    context 'when the rehearsal does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Rehearsal/)
      end
    end
  end

  # Test suite for DELETE /rehearsals/:id
  describe 'DELETE /rehearsals/:id' do

    before { delete "/api/productions/#{production.id}/rehearsals/#{id}", headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
