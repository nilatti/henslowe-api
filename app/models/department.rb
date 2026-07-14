class Department < ApplicationRecord
  has_many :specializations, dependent: :nullify

  validates :name, presence: true

  default_scope { order('name ASC') }
end
