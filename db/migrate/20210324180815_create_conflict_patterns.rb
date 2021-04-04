class CreateConflictPatterns < ActiveRecord::Migration[6.1]
  def change
    create_table :conflict_patterns do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :space, null: false, foreign_key: true
      t.string :start_time
      t.string :end_time
      t.string :category
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
