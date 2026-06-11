class TheaterDestroyWorker
  include Sidekiq::Worker

  def perform(theater_id)
    theater = Theater.find_by(id: theater_id)
    theater&.destroy
  end
end
