class AddCharacterToJobs < ActiveRecord::Migration[5.2]
  def change
    add_reference :jobs, :character, foreign_key: true
  end
end
