class MakeFakeTheaterWorker
  include Sidekiq::Worker

  def perform(user_id)
    MakeFakeTheater.new(user_id: user_id).run
  end
end
