module Api
  module V1
class ChargesController < ApiController
  Stripe.api_key = ENV['STRIPE_SECRET_KEY']
  def create_checkout_session
    user = User.find(current_user.id)
    if !user.stripe_customer_id
      customer = Stripe::Customer.create({
        email: current_user.email
      });
      user.stripe_customer_id = customer['id']
      user.save
    end
    return_to = safe_return_path(params[:return_to])
    session = Stripe::Checkout::Session.create({
      allow_promotion_codes: true,
      cancel_url: "#{ENV['BASE_URL_FRONT']}#{return_to || '/checkout'}",
      customer: user.stripe_customer_id,
      success_url: "#{ENV['BASE_URL_FRONT']}#{return_to || '/success'}",
      mode: 'subscription',
      line_items: [{
        quantity: 1,
        price: params[:price]
        }]
      })
      render json: {stripeUrl: session.url}
  end

  def update_payment_info
    user = User.find(current_user.id)

    session = Stripe::Checkout::Session.create({
      payment_method_types: ['card'],
      mode: 'setup',
      customer: user.stripe_customer_id,
      setup_intent_data: {
        metadata: {
          subscription_id: user.stripe_subscription_id,
        },
      },
      success_url: "#{ENV['BASE_URL_FRONT']}/account",
      cancel_url: "#{ENV['BASE_URL_FRONT']}/account",
      })
      render json: {stripeUrl: session.url}
  end

  private

  # Only allow same-origin relative paths (e.g. "/invitations/abc123") to prevent
  # this param from being used as an open redirect to an arbitrary external host.
  def safe_return_path(return_to)
    return nil unless return_to.is_a?(String)
    return nil unless return_to.match?(%r{\A/(?!/)})

    return_to
  end
end
  end
end
