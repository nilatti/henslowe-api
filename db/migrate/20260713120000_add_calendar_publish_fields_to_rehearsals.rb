class AddCalendarPublishFieldsToRehearsals < ActiveRecord::Migration[7.2]
  def change
    add_column :rehearsals, :published_at, :datetime
    add_column :rehearsals, :ics_sequence, :integer, default: 0, null: false
  end
end
