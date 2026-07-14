# spec/requests/productions_spec.rb
require 'rails_helper'

RSpec.describe 'Rehearsals API' do
  # Initialize the test data
  let!(:play) { create(:play, :with_full_structure) }
  let!(:production) { create(:production, play: play, start_date: Date.today, end_date: 6.weeks.from_now) }
  let!(:scenes) { [play.reload.scenes.first]}
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
      get "/api/v1/productions/#{production.id}/rehearsals", headers: authenticated_header(user)
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
      get "/api/v1/productions/#{production.id}/rehearsals", params: {start_time: production.start_date, end_time: production.start_date + 1.week}, as: :json, headers: authenticated_header(user)
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
      get "/api/v1/french_scenes/#{french_scene_id}/rehearsals", headers: authenticated_header(user)
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
      get "/api/v1/scenes/#{scene_id}/rehearsals", headers: authenticated_header(user)
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
      get "/api/v1/acts/#{act_id}/rehearsals", headers: authenticated_header(user)
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
    before { get "/api/v1/rehearsals/#{id}", headers: authenticated_header(user) }

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
      before { post "/api/v1/productions/#{production.id}/rehearsals", params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'returns status code 201' do
        expect(response).to have_http_status(200)
      end
    end

    # context 'when an invalid request' do
    #   before { post "/api/v1/productions/#{production.id}/rehearsals", params: { rehearsal: { start_time: Time.now, end_time: Time.now - 4.hours, production_id: production.id } }, as: :json, headers: authenticated_header(user) }
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

    before { put "/api/v1/rehearsals/#{id}", params: valid_attributes, as: :json, headers: authenticated_header(user) }

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

    before { delete "/api/v1/rehearsals/#{id}", headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

  describe 'conflict syncing' do
    let!(:space) { create(:space) }
    let!(:called_users) { create_list(:user, 2) }
    let!(:timed_attributes) do
      {
        rehearsal: {
          production_id: production.id,
          start_time: Time.now,
          end_time: Time.now + 1.hour,
          space_id: space.id,
          user_ids: called_users.map(&:id)
        }
      }
    end

    describe 'POST creates conflicts for space and called users' do
      before { post "/api/v1/productions/#{production.id}/rehearsals", params: timed_attributes, as: :json, headers: authenticated_header(user) }

      it 'creates a space conflict' do
        rehearsal = Rehearsal.last
        expect(rehearsal.conflicts.where(space: space, user: nil).count).to eq(1)
      end

      it 'creates a conflict for each called user' do
        rehearsal = Rehearsal.last
        expect(rehearsal.conflicts.where(user_id: called_users.map(&:id), space: nil).count).to eq(2)
      end

      it 'sets category to rehearsal' do
        expect(Rehearsal.last.conflicts.pluck(:category).uniq).to eq(['rehearsal'])
      end
    end

    describe 'PUT updates conflicts when users or space change' do
      let!(:rehearsal) do
        r = Rehearsal.create!(production: production, start_time: Time.now, end_time: Time.now + 1.hour, space: space)
        r.users = called_users
        r.sync_conflicts
        r
      end
      let!(:new_user) { create(:user) }

      before do
        put "/api/v1/rehearsals/#{rehearsal.id}",
            params: { rehearsal: { user_ids: [new_user.id], space_id: nil } },
            as: :json,
            headers: authenticated_header(user)
      end

      it 'removes conflicts for users no longer called' do
        expect(Conflict.where(rehearsal: rehearsal, user_id: called_users.map(&:id)).count).to eq(0)
      end

      it 'creates a conflict for the newly added user' do
        expect(Conflict.where(rehearsal: rehearsal, user: new_user).count).to eq(1)
      end

      it 'removes the space conflict when space is cleared' do
        expect(Conflict.where(rehearsal: rehearsal, user_id: nil).count).to eq(0)
      end
    end

    describe 'DELETE cascades to conflicts' do
      let!(:rehearsal) do
        r = Rehearsal.create!(production: production, start_time: Time.now, end_time: Time.now + 1.hour, space: space)
        r.users = called_users
        r.sync_conflicts
        r
      end

      before { delete "/api/v1/rehearsals/#{rehearsal.id}", headers: authenticated_header(user) }

      it 'destroys all associated conflicts' do
        expect(Conflict.where(rehearsal_id: rehearsal.id).count).to eq(0)
      end
    end
  end

  describe 'DELETE /rehearsals/:id when the rehearsal was already published' do
    let!(:rehearsal) do
      r = create(:rehearsal, production: production, start_time: 1.day.from_now, end_time: 1.day.from_now + 2.hours)
      r.user_ids = [user.id]
      r
    end

    context 'with people already invited' do
      before { PublishRehearsalCalendar.new(production).run }

      it 'emails a cancellation to everyone who was invited' do
        expect {
          delete "/api/v1/rehearsals/#{rehearsal.id}", headers: authenticated_header(user)
        }.to have_enqueued_mail(RehearsalCalendarMailer, :cancel_deleted).with(hash_including(uid: "rehearsal-#{rehearsal.id}@henslowescloud.com"), user.id)
      end

      it 'still destroys the rehearsal' do
        delete "/api/v1/rehearsals/#{rehearsal.id}", headers: authenticated_header(user)
        expect(Rehearsal.find_by(id: rehearsal.id)).to be_nil
      end
    end

    context 'when the rehearsal was never published' do
      it 'sends no cancellation email' do
        expect {
          delete "/api/v1/rehearsals/#{rehearsal.id}", headers: authenticated_header(user)
        }.not_to have_enqueued_mail(RehearsalCalendarMailer)
      end
    end
  end
end
