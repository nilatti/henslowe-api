class FrenchScene < ApplicationRecord
  include OnStageable
  belongs_to :scene
  has_many :entrance_exits, dependent: :destroy
  has_many :lines, dependent: :destroy
  # has_many :labels, dependent: :destroy
  has_many :sound_cues, dependent: :destroy
  has_many :on_stages, dependent: :destroy
  accepts_nested_attributes_for :on_stages, reject_if: :all_blank, allow_destroy: :true
  validates_associated :on_stages
  has_many :characters, through: :on_stages
  has_many :character_groups, through: :on_stages
  has_many :users, through: :on_stages
  has_many :stage_directions, dependent: :destroy
  has_and_belongs_to_many :rehearsals

  validates :number, presence: true

  default_scope {order(:number)}

  def self.play_order(french_scenes)
    french_scenes.sort_by(&:pretty_name)
  end

  def pretty_name
    "#{self.scene.act.number}.#{self.scene.number}.#{self.number}"
  end
end
