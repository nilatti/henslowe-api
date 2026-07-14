class CreateRehearsalInvites < ActiveRecord::Migration[7.2]
  def change
    create_table :rehearsal_invites do |t|
      t.bigint :rehearsal_id, null: false
      t.bigint :user_id, null: false
      t.datetime :sent_at, null: false

      t.timestamps
    end

    add_index :rehearsal_invites, :rehearsal_id
    add_index :rehearsal_invites, :user_id
    add_index :rehearsal_invites, [:rehearsal_id, :user_id], unique: true
  end
end
