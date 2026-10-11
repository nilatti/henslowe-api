class Act < ApplicationRecord
  include OnStageable
  include LineCountable
  belongs_to :play
  has_many :scenes, dependent: :destroy
  has_many :french_scenes, through: :scenes
  has_many :lines, through: :french_scenes
  has_many :on_stages, through: :french_scenes
  has_and_belongs_to_many :rehearsals
  acts_as_list scope: :play
  # Play order is position; number is only the label ("Act 3").
  default_scope {order(:position)}

  validates :number, presence: true

  def pretty_name
    "Act %02d" % self.number
  end

  def self.play_order(acts)
    acts.sort_by { |a| a.position.to_i }
  end

end
