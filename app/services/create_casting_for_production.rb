class CreateCastingForProduction
  def initialize(play_id:, production_id:)
    @play = Play.find(play_id)
    @characters = @play.characters
    @production = Production.find(production_id)
    @specialization = Specialization.find_by(title: 'Actor')
  end
  def create_castings
    ActiveRecord::Base.connection_pool.with_connection do
      @play.copy_status = 'creating casting slots'
      @play.save
    end
    @characters.each do |character|
      ActiveRecord::Base.connection_pool.with_connection do
        job = Job.create!(
          character: character,
          end_date: @production.end_date,
          production: @production,
          specialization: @specialization,
          start_date: @production.start_date,
          theater: @production.theater
        )
      end
    end
  end
end
