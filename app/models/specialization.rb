class Specialization < ApplicationRecord
  validates :title, presence: true
  has_many :jobs
  default_scope { order('title ASC') }
  scope :actor, -> { where title: 'Actor' }
  scope :auditioner, -> { where title: 'Auditioner' }
  scope :actor_or_auditioner, -> { actor.or(auditioner)}
end
