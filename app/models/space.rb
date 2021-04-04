class Space < ApplicationRecord
  has_many :conflicts, dependent: :destroy
  has_many :conflict_patterns, dependent: :destroy
  has_many :space_agreements, dependent: :destroy
  has_many :theaters, through: :space_agreements

  validates :name, presence: true
end
