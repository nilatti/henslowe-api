class MakeFakeTheater
  def initialize(user_id:)
    @specialization = Specialization.find_by(title: "Theater Admin")
    @user = User.find(user_id)
  end
  def run
    theater = Theater.create!(fake: true, name: "#{@user.first_name}'s Dream Theater", mission_statement: "This is a space for #{@user.first_name} to create dream productions, play with text, and imagine.")
    Job.create!(theater_id: theater.id, specialization_id: @specialization.id, user_id: @user.id )
  end
end
