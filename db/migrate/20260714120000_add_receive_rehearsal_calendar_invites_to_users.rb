class AddReceiveRehearsalCalendarInvitesToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :receive_rehearsal_calendar_invites, :boolean, default: true, null: false
  end
end
