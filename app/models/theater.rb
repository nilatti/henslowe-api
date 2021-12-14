class Theater < ApplicationRecord
  has_many :jobs, dependent: :destroy
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
end
