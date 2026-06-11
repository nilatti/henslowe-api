class ProductionPhase < ApplicationRecord
  belongs_to :production
  belongs_to :phase
  validates :phase_id, uniqueness: { scope: :production_id }
end
