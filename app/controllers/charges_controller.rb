class ChargesController < ApiController
  def create
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']

    # order = Order.find(params[:orderId])
    amount = 500

    charge = Stripe::Charge.create(
      # :customer => customer.id,
      :amount => amount,
      :description => "test",
      :currency => "usd",
      :source => params[:stripe_token]
    )
  rescue Stripe::CardError => e
    flash[:errors] = e.message
    redirect_to charges_path
  end

  def create_checkout_session
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
    prices = Stripe::Price.list(
      lookup_keys: [params['lookup_key']],
      expand: ['data.product']
    )

    begin
      session = Stripe::Checkout::Session.create({
        mode: 'subscription',
        line_items: [{
          quantity: 1,
          price: prices.data[0].id
        }],
        success_url: YOUR_DOMAIN + '/success.html?session_id={CHECKOUT_SESSION_ID}',
        cancel_url: YOUR_DOMAIN + '/cancel.html',
      })
    rescue StandardError => e
      halt 400,
          { 'Content-Type' => 'application/json' },
          { 'error': { message: e.error.message } }.to_json
    end
    puts(session.url)

    redirect session.url, 303
  end
end
