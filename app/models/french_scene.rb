class FrenchScene < ApplicationRecord
  include OnStageable
  include LineCountable
  belongs_to :scene
  has_many :entrance_exits, dependent: :destroy
  has_many :lines, dependent: :delete_all
  # has_many :labels, dependent: :destroy
  has_many :sound_cues, dependent: :delete_all
  has_many :on_stages, dependent: :delete_all
  has_many :songs, dependent: :destroy
  accepts_nested_attributes_for :on_stages, reject_if: :all_blank, allow_destroy: :true
  validates_associated :on_stages
  has_many :characters, through: :on_stages
  has_many :character_groups, through: :on_stages
  has_many :users, through: :on_stages
  has_many :stage_directions, dependent: :destroy
  has_and_belongs_to_many :rehearsals

  validates :number, presence: true

  acts_as_list scope: :scene
  # Order within the scene is position; number is only the label.
  default_scope {order(:position)}

  def self.play_order(french_scenes)
    french_scenes = french_scenes.includes(scene: :act) if french_scenes.respond_to?(:includes)
    french_scenes.sort_by { |fs| [fs.scene.act.position.to_i, fs.scene.position.to_i, fs.position.to_i] }
  end

  def pretty_name
    "#{'%02d' % self.scene.act.number}.#{'%02d' % self.scene.number}.#{self.number}"
  end
end
