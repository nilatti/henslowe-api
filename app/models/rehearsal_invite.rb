class RehearsalInvite < ApplicationRecord
  belongs_to :rehearsal
  belongs_to :user
end
