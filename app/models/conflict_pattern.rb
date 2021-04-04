class ConflictPattern < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :space, optional: true
  has_many :conflicts, dependent: :destroy
  validate :check_for_space_and_user
  validates_presence_of :start_time, :end_time, :start_date, :end_date

  def check_for_space_and_user
    if !space && !user
      errors.add(:conflict_pattern, "Must have either user or space")
    end
    if space && user
      errors.add(:conflict_pattern, "You can only have a space OR a user, not both.")
    end
  end
end
