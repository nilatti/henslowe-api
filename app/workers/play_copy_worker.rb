class PlayCopyWorker
  include Sidekiq::Worker

  def perform(play_id, production_id)
    CopyPlayForProduction.new(play_id: play_id, production_id: production_id).run
  end
end
