class StripeWebhooksController < ActionController::API
  def create
    request.body.rewind
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']

    event = Stripe::Webhook.construct_event(
      payload, sig_header, ENV['STRIPE_WEBHOOK_SECRET']
    )

    case event.type
    when 'customer.subscription.updated', 'customer.subscription.deleted'
      sync_subscription(event.data.object)
    end

    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    head :bad_request
  end

  private

  def sync_subscription(subscription)
    user = User.find_by(stripe_customer_id: subscription.customer)
    return unless user

    user.update(
      subscription_status: subscription.status,
      subscription_end_date: Time.at(subscription.current_period_end).to_date
    )
  end
end
