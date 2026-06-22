class Play < ApplicationRecord
  include OnStageable
  belongs_to :author
  belongs_to :production, optional: true

  default_scope {order(:title)}

  serialize :genre, type: Array
  has_many :words, dependent: :delete_all
  has_many :acts, -> { order(:number) }, dependent: :destroy
  has_many :characters, -> { order(:name) }, dependent: :destroy
  has_many :character_groups, dependent: :destroy
  has_many :scenes, through: :acts
  has_many :french_scenes, through: :scenes
  has_many :on_stages, through: :french_scenes
  has_many :lines, through: :french_scenes
  validates :title, presence: true

  def has_lines
    lines.exists?
  end
end
