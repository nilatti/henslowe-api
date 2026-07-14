class Scene < ApplicationRecord
  include OnStageable
  belongs_to :act
  has_many :french_scenes, dependent: :destroy
  has_many :lines, through: :french_scenes
  has_many :on_stages, through: :french_scenes
  has_and_belongs_to_many :rehearsals

  validates :number, presence: true

  default_scope {order(:number)}

  def pretty_name
    "%02d.%02d" % [self.act.number, self.number]
  end

  def self.play_order(scenes)
    scenes.sort_by(&:pretty_name)
  end

end
