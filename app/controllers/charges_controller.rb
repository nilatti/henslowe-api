class ChargesController < ApiController
  def create_payment_intent
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
    user = User.find(current_user.id)
    if !user.stripe_customer_id
      customer = Stripe::Customer.create({
        email: current_user.email
      });
      user.stripe_customer_id = customer['id']
      user.save
    end
    intent = Stripe::PaymentIntent.create({
      amount: params[:amount],
      automatic_payment_methods: {
        enabled: true,
      },
      currency: 'usd',
      customer: user.stripe_customer_id,
      setup_future_usage: 'off_session'
    })
    render json: {clientSecret: intent.client_secret}
  end

  def create_checkout_session
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
    user = User.find(current_user.id)
    if !user.stripe_customer_id
      customer = Stripe::Customer.create({
        email: current_user.email
      });
      user.stripe_customer_id = customer['id']
      user.save
    end
    session = Stripe::Checkout::Session.create({
      cancel_url: "http://localhost:3000/",
      customer: user.stripe_customer_id,
      success_url: "http://localhost:3000/",
      mode: 'subscription',
      line_items: [{
        quantity: 1,
        price: params[:price]
        }]
      })
      render json: {stripeUrl: session.url}
  end
end
