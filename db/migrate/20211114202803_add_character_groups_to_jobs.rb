class AddCharacterGroupsToJobs < ActiveRecord::Migration[6.1]
  def change
    add_reference :jobs, :character_group, index: true
  end
end
