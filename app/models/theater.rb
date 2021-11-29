class Theater < ApplicationRecord
  has_many :jobs, dependent: :destroy
  has_many :productions, dependent: :destroy
  has_many :space_agreements, dependent: :destroy
  has_many :spaces, through: :space_agreements
  has_many :users, through: :jobs
  validates_presence_of :name
  default_scope { order('name ASC') }
end
