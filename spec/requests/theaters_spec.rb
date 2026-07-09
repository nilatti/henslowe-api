require 'rails_helper'

RSpec.describe 'theaters API', type: :request do
  # initialize test data
  let!(:theaters) { create_list(:theater, 10, :has_spaces) }
  let(:theater_id) { theaters.first.id }
  let!(:user) { create(:user, role: 'superadmin') }
  # Test suite for GET /theaters
  describe 'GET /theaters' do
    before(:context) { Theater.destroy_all }
    # make HTTP get request before each example
    before { get '/api/v1/theaters', headers: authenticated_header(user) }

    it 'returns theaters' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json).not_to be_empty
      expect(json.size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /theaters/:id
  describe 'GET api/theaters/:id' do
    before { get "/api/v1/theaters/#{theater_id}", headers: authenticated_header(user) }
    context 'when the record exists' do
      it 'returns the theater' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(theater_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'includes spaces' do
        expect(json['spaces'].size).to eq(3)
      end
    end

    context 'when the record does not exist' do
      let(:theater_id) { 100 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Theater/)
      end
    end
  end

  # Test suite for POST /theaters
  describe 'POST /theaters' do
    # valid payload
    let(:valid_attributes) { { theater: { name: 'The Great American Theater Company' } } }

    context 'when the request is valid' do
      before { post '/api/v1/theaters', params: valid_attributes, as: :json, headers: authenticated_header(user) }

      it 'creates a theater' do
        expect(json['name']).to eq('The Great American Theater Company')
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      before { post '/api/v1/theaters', params: { theater: { address: 'Failure' } }, as: :json, headers: authenticated_header(user) }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(JSON.parse(response.body)['name']).to include("can't be blank")
      end
    end
  end

  # Test suite for PUT /theaters/:id
  describe 'PUT /api/theaters/:id' do
    let(:valid_attributes) { { theater: { name: 'The Great American Theater Company' } } }

    context 'when the record exists' do
      before { put "/api/v1/theaters/#{theater_id}", params: valid_attributes, as: :json, headers: authenticated_header(user)}

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end
  end

  # Test suite for DELETE /theaters/:id
  describe 'DELETE /theaters/:id' do
    before { delete "/api/v1/theaters/#{theater_id}", headers: authenticated_header(user) }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end

  # Test suite for create_seat_subscription_checkout_session
  describe 'POST /theaters/:id/create_seat_subscription_checkout_session' do
    let!(:theater) { create(:theater) }
    let!(:admin_user) { create(:user, :paid) }
    let!(:theater_admin_job) do
      create(:job, user: admin_user, theater: theater, production: nil,
                   specialization: create(:specialization, :theater_admin))
    end
    let!(:regular_user) { create(:user) }
    let(:fake_session) { double(url: 'https://checkout.stripe.com/session/xyz') }

    context 'as a theater admin, with no existing stripe_customer_id' do
      before do
        allow(Stripe::Customer).to receive(:create).and_return({ 'id' => 'cus_new' })
        allow(Stripe::Checkout::Session).to receive(:create).and_return(fake_session)
        post "/api/v1/theaters/#{theater.id}/create_seat_subscription_checkout_session",
             params: { price: 'price_123' }, as: :json, headers: authenticated_header(admin_user)
      end

      it 'creates a Stripe customer for the theater and returns the checkout url' do
        expect(response).to have_http_status(:ok)
        expect(json['stripeUrl']).to eq('https://checkout.stripe.com/session/xyz')
        expect(theater.reload.stripe_customer_id).to eq('cus_new')
      end

      it 'requests a subscription-mode session with quantity 1' do
        expect(Stripe::Checkout::Session).to have_received(:create).with(
          hash_including(mode: 'subscription', customer: 'cus_new', line_items: [{ quantity: 1, price: 'price_123' }])
        )
      end
    end

    context 'as a non-admin' do
      it 'is forbidden' do
        post "/api/v1/theaters/#{theater.id}/create_seat_subscription_checkout_session",
             params: { price: 'price_123' }, as: :json, headers: authenticated_header(regular_user)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with a quantity param, for a bulk seat pre-purchase' do
      before do
        allow(Stripe::Customer).to receive(:create).and_return({ 'id' => 'cus_new' })
        allow(Stripe::Checkout::Session).to receive(:create).and_return(fake_session)
        post "/api/v1/theaters/#{theater.id}/create_seat_subscription_checkout_session",
             params: { price: 'price_123', quantity: 5 }, as: :json, headers: authenticated_header(admin_user)
      end

      it 'persists reserved_seats and requests that quantity from Stripe' do
        expect(theater.reload.reserved_seats).to eq(5)
        expect(Stripe::Checkout::Session).to have_received(:create).with(
          hash_including(line_items: [{ quantity: 5, price: 'price_123' }])
        )
      end
    end

    context 'with a quantity param of 0 or less' do
      before do
        allow(Stripe::Customer).to receive(:create).and_return({ 'id' => 'cus_new' })
        allow(Stripe::Checkout::Session).to receive(:create).and_return(fake_session)
      end

      it 'floors it at 1 rather than rejecting the request' do
        post "/api/v1/theaters/#{theater.id}/create_seat_subscription_checkout_session",
             params: { price: 'price_123', quantity: 0 }, as: :json, headers: authenticated_header(admin_user)
        expect(response).to have_http_status(:ok)
        expect(theater.reload.reserved_seats).to eq(1)
      end
    end
  end

  # Test suite for update_reserved_seats
  describe 'PATCH /theaters/:id/update_reserved_seats' do
    let!(:theater) { create(:theater, stripe_customer_id: 'cus_123', subscription_status: 'active') }
    let!(:admin_user) { create(:user, :paid) }
    let!(:theater_admin_job) do
      create(:job, user: admin_user, theater: theater, production: nil,
                   specialization: create(:specialization, :theater_admin))
    end
    let!(:regular_user) { create(:user) }
    let(:subscription_item) { double(id: 'si_123', quantity: 1) }
    let(:subscription) { double(items: double(data: [subscription_item])) }

    before do
      allow(Stripe::Subscription).to receive(:list).with(customer: 'cus_123').and_return(double(data: [subscription]))
      allow(Stripe::SubscriptionItem).to receive(:update)
    end

    it 'updates reserved_seats and immediately syncs the Stripe subscription quantity' do
      patch "/api/v1/theaters/#{theater.id}/update_reserved_seats",
            params: { reserved_seats: 4 }, as: :json, headers: authenticated_header(admin_user)
      expect(response).to have_http_status(:ok)
      expect(theater.reload.reserved_seats).to eq(4)
      expect(Stripe::SubscriptionItem).to have_received(:update).with('si_123', quantity: 4, proration_behavior: 'always_invoice')
    end

    it 'rejects a value below 1' do
      patch "/api/v1/theaters/#{theater.id}/update_reserved_seats",
            params: { reserved_seats: 0 }, as: :json, headers: authenticated_header(admin_user)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'is forbidden for a non-admin' do
      patch "/api/v1/theaters/#{theater.id}/update_reserved_seats",
            params: { reserved_seats: 4 }, as: :json, headers: authenticated_header(regular_user)
      expect(response).to have_http_status(:forbidden)
    end
  end

  # Test suite for theater_names
  describe 'GET /api/theaters/theater_names' do
    before(:context) { Theater.destroy_all }
    before { get '/api/v1/theaters/theater_names', headers: authenticated_header(user) }

    it 'returns theaters ONLY NAMES' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json.first['name']).not_to be_empty
      expect(json.first['address']).to be_nil
      expect(json).not_to be_empty
      expect(json.size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end
end
