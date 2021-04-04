class Conflict < ApplicationRecord
  belongs_to :conflict_pattern, optional: true
  belongs_to :user, optional: true
  belongs_to :space, optional: true
  validate :check_for_space_and_user
  validates_presence_of :start_time, :end_time

  def check_for_space_and_user
    if !space && !user
      errors.add(:conflict, "Must have either user or space")
    end
    if space && user
      errors.add(:conflict, "You can only have a space OR a user, not both.")
    end
  end
end
