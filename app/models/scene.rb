class Scene < ApplicationRecord
  include OnStageable
  include LineCountable
  belongs_to :act
  has_many :french_scenes, dependent: :destroy
  has_many :lines, through: :french_scenes
  has_many :on_stages, through: :french_scenes
  has_and_belongs_to_many :rehearsals

  validates :number, presence: true

  acts_as_list scope: :act
  # Order within the act is position; number is only the label.
  default_scope {order(:position)}

  def pretty_name
    "%02d.%02d" % [self.act.number, self.number]
  end

  def self.play_order(scenes)
    scenes = scenes.includes(:act) if scenes.respond_to?(:includes)
    scenes.sort_by { |s| [s.act.position.to_i, s.position.to_i] }
  end

end
