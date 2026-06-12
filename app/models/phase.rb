class Phase < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  has_many :production_phases, dependent: :destroy
  has_many :specializations_with_start, class_name: 'Specialization', foreign_key: :default_start_phase_id, dependent: :nullify
  has_many :specializations_with_end, class_name: 'Specialization', foreign_key: :default_end_phase_id, dependent: :nullify
  default_scope { order(Arel.sql('position IS NULL, position, name')) }
end
