require 'rails_helper'

RSpec.describe 'CanCan permissions test' do
  # Initialize the test data
    include ApiHelper
    let!(:super_user) { create(:user, role: "superadmin")}
    let!(:actor_user) { create(:user)}
    let!(:theater) { create(:theater) }
    let!(:bad_theater) { create(:theater)}
    let!(:production) { create(:production, theater: theater)}
    let!(:bad_production) { create(:production, theater: theater)}
    let!(:super_bad_production) { create(:production, theater: bad_theater)}
    let!(:play) { create(:play)}
    let!(:acting_specialization) {create(:specialization, :actor)}
    let!(:production_job_nonadmin) { create(:job, user: actor_user, production: production, specialization: acting_specialization)}

    describe 'super admin can see all' do
        before {
            get "/api/productions/#{production.id}", headers: authenticated_header(super_user), as: :json
        }
        it 'returns status code 200' do
            expect(response).to have_http_status(200)
          end
    end

    describe 'all logged-in users can see all play texts' do 
        before {
            get "/api/plays/#{play.id}", headers: authenticated_header(actor_user), as: :json
            }
        
            context 'when user has permissions' do
            it 'returns status code 200' do
                expect(response).to have_http_status(200)
            end
        end
    end 
    
  describe 'check that actors can see info on their own production and theater, but not other productions or theaters' do

      it 'returns status code 200 for allowed production' do
        get "/api/productions/#{production.id}", headers: authenticated_header(actor_user), as: :json
        expect(response).to have_http_status(200)
      end

      it 'does not return 200 for blocked production at same theater' do
        get "/api/productions/#{bad_production.id}", headers: authenticated_header(actor_user), as: :json
        expect(response).to have_http_status(403)
      end

      it 'does not return 200 for blocked production at different theater' do
        get "/api/productions/#{super_bad_production.id}", headers: authenticated_header(actor_user), as: :json
        expect(response).to have_http_status(403)
      end
  end
end