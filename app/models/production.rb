class Production < ApplicationRecord
  attr_accessor :play_id
  belongs_to :theater
  belongs_to :default_space, class_name: 'Space', optional: true
  has_many :jobs, dependent: :destroy
  has_many :users, through: :jobs
  has_and_belongs_to_many :default_call_users,
    class_name: 'User',
    join_table: 'production_default_calls',
    foreign_key: :production_id,
    association_foreign_key: :user_id

  has_one :play, dependent: :destroy

  has_many :production_phases, dependent: :destroy
  has_many :stage_exits, dependent: :destroy
  has_many :rehearsals, dependent: :destroy

  validate :end_date_after_start_date

  default_scope {order(:start_date)}
private
  def end_date_after_start_date
    return unless start_date && end_date
    if start_date > end_date
      errors.add(:end_date, "can't be before start date")
    end
  end
end
