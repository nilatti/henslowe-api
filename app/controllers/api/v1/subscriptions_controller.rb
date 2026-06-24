module Api
  module V1
    class SubscriptionsController < ApiController
      def index
        prices = Stripe::Price.list({ active: true })
        products = []
        prices.each do |price|
          api_product = Stripe::Product.retrieve(price.product)
          api_product.price = price.id
          api_product.amount = price.unit_amount
          products.push(api_product)
        end
        render json: products.to_json
      end

      def user_subscriptions
        products = []
        if current_user.stripe_customer_id
          subscriptions = SubscriptionStatus.new
            .get_subscriptions_for_user(current_user.stripe_customer_id).data
          subscriptions.each do |subscription|
            api_product = Stripe::Product.retrieve(subscription.plan.product)
            api_product.subscription_id = subscription.id
            api_product.amount = subscription.plan.amount
            api_product.current_period_end = subscription.current_period_end
            api_product.current_period_start = subscription.current_period_start
            api_product.status = subscription.status
            api_product.cancel_at_period_end = subscription.cancel_at_period_end
            api_product.interval = subscription.plan.interval
            api_product.price_id = subscription.items.data[0].price.id
            products.push(api_product)
          end
        end
        render json: products.to_json
      end

      def cancel
        subscription = Stripe::Subscription.retrieve(params[:subscription_id])
        raise CanCan::AccessDenied unless subscription.customer == current_user.stripe_customer_id
        result = Stripe::Subscription.update(params[:subscription_id], { cancel_at_period_end: true })
        render json: result.to_json
      end

      def renew
        subscription = Stripe::Subscription.retrieve(params[:subscription_id])
        raise CanCan::AccessDenied unless subscription.customer == current_user.stripe_customer_id
        result = Stripe::Subscription.update(params[:subscription_id], { cancel_at_period_end: false })
        render json: result.to_json
      end
    end
  end
end
