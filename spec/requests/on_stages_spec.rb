require 'rails_helper'

RSpec.describe "OnStages", type: :request do
  describe "GET /on_stages" do
    it "works! (now write some real specs)" do
      get on_stages_path
      expect(response).to have_http_status(200)
    end
  end
end
