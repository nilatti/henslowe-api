class BuildConflictsScheduleWorker
  include Sidekiq::Worker

  def perform(
    days_of_week,
    end_time,
    start_time
    user_id,
    )
    user_id = user_id.to_i
    days_of_week = days_of_week.split(',')
    BuildConflictsSchedule.new(days_of_week: days_of_week, end_time: end_time, user_id: user_id, start_time: start_time).run
  end

  def cancelled?
    Sidekiq.redis {|c| c.exists("cancelled-#{jid}") }
  end

  def self.cancel!(jid)
    Sidekiq.redis {|c| c.setex("cancelled-#{jid}", 86400, 1) }
  end
end
