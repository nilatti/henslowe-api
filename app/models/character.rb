class Character < ApplicationRecord
  belongs_to :play
  belongs_to :character_group, optional: :true
  has_many :jobs, dependent: :destroy
  has_many :on_stages, dependent: :destroy
  has_many :french_scenes, through: :on_stages
  has_many :lines, dependent: :destroy
  has_many :users, through: :jobs
  has_and_belongs_to_many :entrance_exits, dependent: :destroy
  has_and_belongs_to_many :stage_directions, dependent: :destroy
  default_scope { order('name ASC') }
  validates :name, presence: true

  before_save :downcase_gender_and_age

  private
  def downcase_gender_and_age
    if self.gender
      self.gender = self.gender.downcase
    end
    if self.age
      self.age = self.age.downcase
    end
  end
end
