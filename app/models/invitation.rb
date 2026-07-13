class Invitation < ApplicationRecord
  enum :status, { pending: 0, accepted: 1, revoked: 2, expired: 3 }, default: :pending
  enum :payment_responsibility, { theater_pays: 0, self_pays: 1 }

  belongs_to :theater, optional: true
  belongs_to :production, optional: true
  belongs_to :specialization
  belongs_to :invited_by, class_name: 'User'
  belongs_to :accepted_user, class_name: 'User', optional: true

  before_validation :generate_token, on: :create
  before_validation :set_default_expiry, on: :create
  before_validation :normalize_email

  validates :email, presence: true
  validates :token, presence: true, uniqueness: true
  validates :payment_responsibility, presence: true
  validate :exactly_one_of_theater_or_production
  validate :specialization_is_invitable

  scope :active, -> { pending.where('expires_at > ?', Time.current) }

  # Distinct from the `expired?` the status enum generates (status == "expired"):
  # this is true the moment a still-pending invitation's window has lapsed, before
  # anything has actually transitioned its status.
  def stale?
    pending? && expires_at <= Time.current
  end

private

  def normalize_email
    self.email = email.strip.downcase if email.present?
  end

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(24)
  end

  def set_default_expiry
    self.expires_at ||= 14.days.from_now
  end

  def exactly_one_of_theater_or_production
    if theater_id.present? == production_id.present?
      errors.add(:base, "must belong to exactly one of theater or production")
    end
  end

  def specialization_is_invitable
    return if specialization.nil?
    if %w[Actor Auditioner].include?(specialization.title)
      errors.add(:specialization, "cannot be invited directly — actor/auditioner roles go through casting")
    end
  end
end
