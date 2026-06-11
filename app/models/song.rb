class Song < ApplicationRecord
  belongs_to :french_scene
  has_and_belongs_to_many :characters
  has_and_belongs_to_many :character_groups
  acts_as_list scope: :french_scene

  validates :title, presence: true
end
