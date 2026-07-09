class Theater < ApplicationRecord
  has_many :jobs, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :productions, dependent: :destroy
  has_many :space_agreements, dependent: :destroy
  has_many :spaces, through: :space_agreements
  has_many :users, through: :jobs
  validates_presence_of :name
  default_scope { order('name ASC') }
  # after_create :make_new_fake_theater

  def make_new_fake_theater
    specialization = Specialization.find_by(title: "Theater Admin")
    Job.create!(theater_id: @theater.id, specialization_id: specialization.id, user_id: current_user.id )
  end

  def has_active_subscription?
    subscription_status == 'active'
  end

  # Currently-active jobs sponsored by this theater's billing — spans jobs
  # directly on the theater and jobs on any of the theater's productions,
  # mirroring the `theater = self.theater || self.production&.theater`
  # pattern already used in Job#user_must_be_subscribed_for_paid_role.
  def sponsored_jobs
    Job.where(theater_sponsored: true)
       .where('theater_id = :theater_id OR production_id IN (:production_ids)',
              theater_id: id, production_ids: production_ids)
       .where('end_date IS NULL OR end_date >= ?', Date.current)
  end

  # Keeps quantity at a minimum of 1 once billing is turned on, rather than
  # letting it drop to 0 when nothing is currently sponsored.
  def sync_seat_quantity!
    return if stripe_customer_id.blank?

    subscription = Stripe::Subscription.list(customer: stripe_customer_id).data.first
    return unless subscription

    item = subscription.items.data.first
    return unless item

    quantity = [sponsored_jobs.count, 1].max
    return if item.quantity == quantity

    Stripe::SubscriptionItem.update(item.id, quantity: quantity, proration_behavior: 'always_invoice')
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe error syncing seat quantity for theater #{id}: #{e.message}")
  end
end
