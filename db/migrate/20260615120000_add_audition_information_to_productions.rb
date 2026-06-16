class AddAuditionInformationToProductions < ActiveRecord::Migration[7.1]
  def change
    add_column :productions, :audition_information, :text
  end
end
