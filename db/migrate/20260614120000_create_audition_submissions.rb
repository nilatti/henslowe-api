class CreateAuditionSubmissions < ActiveRecord::Migration[7.1]
  def change
    create_table :audition_submissions do |t|
      t.references :job, null: false, foreign_key: true
      t.string :video_url
      t.text :notes
      t.timestamps
    end
  end
end
