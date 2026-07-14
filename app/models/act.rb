class Act < ApplicationRecord
  include OnStageable
  belongs_to :play
  has_many :scenes, dependent: :destroy
  has_many :french_scenes, through: :scenes
  has_many :lines, through: :french_scenes
  has_many :on_stages, through: :french_scenes
  has_and_belongs_to_many :rehearsals
  default_scope {order(:number)}

  validates :number, presence: true

  def pretty_name
    "Act %02d" % self.number
  end

  def self.play_order(acts)
    acts.sort_by(&:pretty_name)
  end

end
