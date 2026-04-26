class CharacterGroup < ApplicationRecord
  belongs_to :play
  has_many :characters, dependent: :destroy
  has_many :on_stages, dependent: :destroy
  has_many :lines, dependent: :destroy
  has_and_belongs_to_many :entrance_exits, dependent: :destroy
  has_and_belongs_to_many :stage_directions, dependent: :destroy
  validates :name, presence: true
end
