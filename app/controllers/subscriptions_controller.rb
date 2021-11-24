class SubscriptionsController < ApiController
  def index
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
    prices = Stripe::Price.list()
    print(prices)
    products = []
    prices.each do |price|
      api_product = Stripe::Product.retrieve(price.product)
      api_product.price = price.id
      api_product.amount = price.unit_amount
      products.push(api_product)
    end
    render json: products.to_json
  end
end
