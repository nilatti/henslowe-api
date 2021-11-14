class Job < ApplicationRecord
  include Filterable
  belongs_to :character, optional: true
  belongs_to :character_group, optional: true
  belongs_to :production, optional: true
  belongs_to :specialization, optional: true
  belongs_to :theater, optional: true
  belongs_to :user, optional: true

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

private
  def end_date_after_start_date
    if end_date
      if start_date > end_date
        errors.add(:end_date, "can't be before start date")
      end
    end
  end
end
