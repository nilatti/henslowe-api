class SubscriptionStatus
  Stripe.api_key = ENV['STRIPE_SECRET_KEY']

  def bulk_update_subscription_statuses(subscriptions)
    inactive_subscriptions = subscriptions.data.select{|subscription| subscription.status != 'active'}
    inactive_subscriptions.each do |subscription|
      user = User.find_by(stripe_customer_id: subscription.customer)
      user.subscription_status = subscription.status
      user.save
    end
  end

  def get_all_subscriptions
    return Stripe::Subscription.list()
  end

  def get_subscriptions_for_user(stripe_customer_id)
    user = User.find_by(stripe_customer_id: stripe_customer_id)
    subscriptions = Stripe::Subscription.list({customer: stripe_customer_id})
    active = subscriptions.data.select{|subscription| subscription.status == 'active'}
    active.sort_by(&:current_period_end)
    user.stripe_subscription_id = active[-1].id
    user.save
    return subscriptions
  end
end
