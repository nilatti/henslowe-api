class AddResumeUrlToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :resume_url, :string
  end
end
