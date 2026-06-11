class Specialization < ApplicationRecord
  validates :title, presence: true
  has_many :jobs
  belongs_to :default_start_phase, class_name: 'Phase', optional: true
  belongs_to :default_end_phase, class_name: 'Phase', optional: true
  default_scope { order('title ASC') }
  scope :actor, -> { where title: 'Actor' }
  scope :auditioner, -> { where title: 'Auditioner' }
  scope :actor_or_auditioner, -> { actor.or(auditioner)}
end
