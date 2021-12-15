class MakeFakeTheaterWorker
  include Sidekiq::Worker

  def perform(user_id)
    MakeFakeTheater.new(user_id: user_id).run
  end
  def cancelled?
    Sidekiq.redis {|c| c.exists("cancelled-#{jid}") }
  end

  def self.cancel!(jid)
    Sidekiq.redis {|c| c.setex("cancelled-#{jid}", 86400, 1) }
  end
end
