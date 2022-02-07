class Production < ApplicationRecord
  attr_accessor :play_id
  belongs_to :theater
  has_many :jobs, dependent: :destroy
  has_many :users, through: :jobs

  has_one :play, dependent: :destroy

  has_many :stage_exits, dependent: :destroy
  has_many :rehearsals, dependent: :destroy

  # validate :end_date_after_start_date

  default_scope {order(:start_date)}
private
  def end_date_after_start_date
   if start_date > end_date
     errors.add(:end_date, "can't be before start date")
   end
 end
end
