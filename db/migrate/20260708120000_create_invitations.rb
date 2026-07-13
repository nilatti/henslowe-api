class CreateInvitations < ActiveRecord::Migration[7.2]
  def change
    create_table :invitations do |t|
      t.string :email, null: false
      t.string :token, null: false
      t.integer :status, default: 0, null: false
      t.integer :payment_responsibility, null: false
      t.bigint :theater_id
      t.bigint :production_id
      t.bigint :specialization_id
      t.bigint :invited_by_id
      t.bigint :accepted_user_id
      t.datetime :expires_at, null: false
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, :email
    add_index :invitations, :theater_id
    add_index :invitations, :production_id
    add_index :invitations, :specialization_id
    add_index :invitations, :invited_by_id
    add_index :invitations, :accepted_user_id
  end
end
