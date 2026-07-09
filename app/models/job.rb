class Job < ApplicationRecord
  include Filterable
  belongs_to :character, optional: true
  belongs_to :character_group, optional: true
  belongs_to :production, optional: true
  belongs_to :specialization, optional: true
  belongs_to :theater, optional: true
  belongs_to :user, optional: true
  has_one :audition_submission, dependent: :destroy

  scope :production, -> (production) { where production: production }
  scope :specialization, -> (specialization) { where specialization: specialization }
  scope :theater, -> (theater) { where theater: theater }
  scope :user, -> (user) { where user: user }
  scope :actor, -> { where(specialization: Specialization.actor).where.not(user: nil) }
  scope :actor_or_auditioner, -> { where(specialization: Specialization.actor_or_auditioner).where.not(user: nil) }
  scope :actor_for_production, -> (production) {production(production).actor}
  scope :actor_or_auditioner_for_production, -> (production) {production(production).actor_or_auditioner}
  scope :actor_or_auditioner_for_theater, -> (theater) {theater(theater).actor_or_auditioner}

  validate :end_date_after_start_date
  validate :no_real_users_at_dream_theaters, on: :create
  validate :user_must_be_subscribed_for_paid_role, on: :create

  after_commit :sync_theater_seat_quantity, if: :theater_sponsored?

private
  def sync_theater_seat_quantity
    (theater || production&.theater)&.sync_seat_quantity!
  end

  def no_real_users_at_dream_theaters
    return unless user.present? && !user.fake?
    theater = self.theater || self.production&.theater
    return unless theater&.fake?
    # The one allowed real-user job at a dream theater is the owner's Theater Admin
    unless specialization&.theater_admin? && theater_id.present? && production_id.nil?
      errors.add(:base, "Dream theater productions cannot have real users as cast or staff")
    end
  end

  def user_must_be_subscribed_for_paid_role
    return unless user.present? && !user.fake?
    return if specialization.nil? || %w[Actor Auditioner].include?(specialization.title)
    theater = self.theater || self.production&.theater
    return if theater&.fake?
    return if theater_sponsored? && theater&.has_active_subscription?
    return if user.has_active_subscription?
    errors.add(:base, "payment_required")
  end

  def end_date_after_start_date
    if end_date
      if start_date > end_date
        errors.add(:end_date, "can't be before start date")
      end
    end
  end
end
