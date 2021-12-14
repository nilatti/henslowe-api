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
    session = Stripe::Checkout::Session.create({
      cancel_url: "#{ENV['BASE_URL_FRONT']}/checkout",
      customer: user.stripe_customer_id,
      success_url: "#{ENV['BASE_URL_FRONT']}/success",
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
end
