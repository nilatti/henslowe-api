require 'rails_helper'

RSpec.describe 'Stripe webhooks', type: :request do
  let(:period_end) { 1.month.from_now.to_i }

  def stub_event(type:, customer:, status: 'active')
    subscription = double(
      customer: customer,
      status: status,
      current_period_end: period_end,
      items: double(data: [double(current_period_end: period_end)])
    )
    event = double(type: type, data: double(object: subscription))
    allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
  end

  # customer.subscription.created is the event Stripe actually sends the moment
  # a brand new subscription is completed — customer.subscription.updated only
  # fires on later changes. Missing this event meant a theater's very first
  # subscription never got its subscription_status set (see production incident:
  # theater 168 had a stripe_customer_id but subscription_status stayed nil).
  %w[customer.subscription.created customer.subscription.updated customer.subscription.deleted].each do |event_type|
    describe "#{event_type} webhook" do
      it "updates a matching User's subscription_status" do
        user = create(:user, stripe_customer_id: 'cus_user_1')
        stub_event(type: event_type, customer: 'cus_user_1', status: 'active')

        post '/stripe/webhook', headers: { 'HTTP_STRIPE_SIGNATURE' => 'sig' }
        expect(response).to have_http_status(:ok)
        expect(user.reload.subscription_status).to eq('active')
      end

      it "updates a matching Theater's subscription_status" do
        theater = create(:theater, stripe_customer_id: 'cus_theater_1')
        stub_event(type: event_type, customer: 'cus_theater_1', status: 'active')

        post '/stripe/webhook', headers: { 'HTTP_STRIPE_SIGNATURE' => 'sig' }
        expect(response).to have_http_status(:ok)
        expect(theater.reload.subscription_status).to eq('active')
      end

      it 'is a no-op when no User or Theater matches the customer id' do
        stub_event(type: event_type, customer: 'cus_unknown', status: 'active')
        post '/stripe/webhook', headers: { 'HTTP_STRIPE_SIGNATURE' => 'sig' }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  it 'rejects a request with an invalid signature' do
    allow(Stripe::Webhook).to receive(:construct_event).and_raise(Stripe::SignatureVerificationError.new('bad sig', 'sig_header'))
    post '/stripe/webhook', headers: { 'HTTP_STRIPE_SIGNATURE' => 'bad' }
    expect(response).to have_http_status(:bad_request)
  end
end
