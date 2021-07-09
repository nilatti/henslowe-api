class UpdateLineCountWorker
  include Sidekiq::Worker

  def perform(line_id)
    puts ('perform called')
    CountLines.new(line_id: line_id).run
  end
  def cancelled?
    Sidekiq.redis {|c| c.exists("cancelled-#{jid}") }
  end

  def self.cancel!(jid)
    Sidekiq.redis {|c| c.setex("cancelled-#{jid}", 86400, 1) }
  end
end
