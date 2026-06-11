class Song < ApplicationRecord
  belongs_to :french_scene
  has_and_belongs_to_many :characters

  validates :title, presence: true
end
