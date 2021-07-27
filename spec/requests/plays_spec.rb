# spec/requests/plays_spec.rb
require 'rails_helper'

RSpec.describe 'Plays API' do
  # Initialize the test data
  let!(:user) { create(:user)}
  let!(:author) { create(:author) }
  let!(:plays) { create_list(:play, 5, author_id: author.id, canonical: true) }
  let!(:other_author_plays) { create_list(:play, 5, canonical: true)}
  let!(:author_id) { author.id }
  let!(:id) { plays.first.id }
  # Test suite for GET /authors/:author_id/plays
  describe 'GET api/authors/:author_id/plays' do
    before {
      get "/api/authors/#{author_id}/plays", params: {play: {author_id: author_id}}, as: :json, headers: authenticated_header(user)
    }

    context 'when author exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all author plays' do
        expect(json.size).to eq(8)
      end
    end
  end

  describe 'GET api/plays' do
    before {
      get "/api/plays", as: :json, headers: authenticated_header(user)
    }

    context 'when there are plays by multiple playwrights' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all plays' do
        expect(json.size).to eq(28)
      end
    end
  end

  # Test suite for GET /authors/:author_id/plays/:id
  describe 'GET /authors/:author_id/plays/:id' do
    before { get "/api/authors/#{author_id}/plays/#{id}", as: :json, headers: authenticated_header(user) }

    context 'when play exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the play' do
        expect(json['id'].to_i).to eq(id)
      end

      it 'has acts, scenes, characters, and french scenes' do
        expect(json['characters'].size).to eq(3)
        expect(json['acts'].size).to eq(3)
        expect(json['acts'][0]['scenes'].size).to eq(3)
        expect(json['acts'][0]['scenes'][0]['french_scenes'].size).to eq(3)
      end
    end

    context 'when author play does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Play/)
      end
    end
  end

  # Test suite for GET /plays/:id
  describe 'GET /plays/:id' do
    before { get "/api/plays/#{id}", as: :json, headers: authenticated_header(user) }

    context 'when play exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the play' do
        expect(json['id']).to eq(id)
      end

      it 'has acts, scenes, characters, and french scenes' do
        expect(json['characters'].size).to eq(3)
        expect(json['acts'].size).to eq(3)
        expect(json['acts'][0]['scenes'].size).to eq(3)
        expect(json['acts'][0]['scenes'][0]['french_scenes'].size).to eq(3)
      end
    end
  end

  # Test suite for PUT /authors/:author_id/plays
  describe 'POST /authors/:author_id/plays' do
    let(:valid_attributes) { { play: { title: 'Give Us Good', author_id: author_id } } }

    context 'when request attributes are valid' do
      before { post "/api/authors/#{author_id}/plays", params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when an invalid request' do
      before { post "/api/authors/#{author_id}/plays", params: { play: { genre: 'failure' } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a failure message' do
        expected_response = "{\"author\":[\"must exist\"],\"title\":[\"can't be blank\"]}"
        expect(response.body).to match(expected_response)
      end
    end
  end

  # Test suite for PUT /authors/:author_id/plays/:id
  describe 'PUT /api/authors/:author_id/plays/:id' do
    let(:valid_attributes) { { play: { title: 'The Magic Flute' } } }

    before { put "/api/authors/#{author_id}/plays/#{id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

    context 'when play exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'updates the play' do
        updated_play = Play.find(id)
        expect(updated_play.title).to match(/The Magic Flute/)
      end
    end

    context 'when the play does not exist' do
      let(:id) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Play/)
      end
    end
  end

  describe 'get play script and skeleton' do

    before {
      french_scene = plays.first.acts.first.scenes.first.french_scenes.first
      create_list(:line, 3, french_scene: french_scene)
      get "/api/plays/#{id}/play_script/", as: :json, headers: authenticated_header(user)
    }
    it 'returns a play script' do
      expect(json['acts'].size).to eq(3)
      expect(json['acts'][0]['scenes'].size).to eq(3)
      expect(json['acts'][0]['scenes'][0]['french_scenes'].size).to eq(3)
      expect(json['acts'][0]['scenes'][0]['french_scenes'][0]).to include('lines')
      expect(json['acts'][0]['scenes'][0]['french_scenes'][0]['lines'].size).to eq(3)
    end

    it 'returns a play skeleton' do
      get "/api/plays/#{id}/play_skeleton/", as: :json, headers: authenticated_header(user)
      expect(json['acts'].size).to eq(3)
      expect(json['acts'][0]['scenes'].size).to eq(3)
      expect(json['acts'][0]['scenes'][0]['french_scenes'].size).to eq(3)
      expect(json['acts'][0]['scenes'][0]['french_scenes'][0]).not_to include(['lines'])
    end
  end

  describe 'get play titles' do
    before { get "/api/plays/play_titles", as: :json, headers: authenticated_header(user) }
    it 'returns play titles' do
      expect(json.size).to eq(10)
      expect(json[0]).to include('title')
      expect(json[0]).to include('id')
      expect(json[0]).not_to include('acts')
    end
  end

  describe 'verify on-stages' do
    before {
      character0 = plays[0].characters[0]
      character1 = plays[0].characters[1]
      character_group = plays[0].character_groups[0]
      french_scene0 = plays[0].acts[0].scenes[0].french_scenes[0]
      french_scene1 = plays[0].acts[0].scenes[0].french_scenes[1]
      french_scene2 = plays[0].acts[0].scenes[1].french_scenes[0]
      french_scene3 = plays[0].acts[1].scenes[0].french_scenes[0]
      create(:on_stage, character: character0, french_scene: french_scene0)
      create(:on_stage, character: character1, french_scene: french_scene0)
      create(:on_stage, character_group: character_group, character: nil, french_scene: french_scene0)
      create(:on_stage, character: character0, french_scene: french_scene1)
      create(:on_stage, character: character1, french_scene: french_scene1)
      create(:on_stage, character: character1, french_scene: french_scene2)
      create(:on_stage, character_group: character_group, character: nil, french_scene: french_scene1)
      create(:on_stage, character: character1, french_scene: french_scene3)
    }

    it 'returns on_stages organized by acts' do
      get "/api/plays/#{id}/play_act_on_stages/", as: :json, headers: authenticated_header(user)
      expect(json.size).to eq(3)
      expect(json[0]['find_on_stages'].size).to eq(3)
      expect(json[1]['find_on_stages'].size).to eq(1)
      expect(json[0]['find_on_stages'][0]).to include('character_id')
      expect(json[0]['find_on_stages'][0]).to include('french_scene_id')
    end

    it 'returns on_stages organized by french_scenes' do
      get "/api/plays/#{id}/play_french_scene_on_stages/", as: :json, headers: authenticated_header(user)
      expect(json.size).to eq(27)
      expect(json[0]['find_on_stages'].size).to eq(3)
      expect(json[1]['find_on_stages'].size).to eq(3)
    end

    it 'returns on_stages organized by scenes' do
      get "/api/plays/#{id}/play_scene_on_stages/", as: :json, headers: authenticated_header(user)
      expect(json.size).to eq(9)
      expect(json[0]['find_on_stages'].size).to eq(3)
    end

    it 'returns on_stages for whole play' do
      get "/api/plays/#{id}/play_on_stages/", as: :json, headers: authenticated_header(user)
      expect(json['find_on_stages'].size).to eq(3)
    end
  end

  # Test suite for DELETE /plays/:id
  describe 'DELETE /authors/:id' do
    before { delete "/api/authors/#{author_id}/plays/#{id}", as: :json, headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end
