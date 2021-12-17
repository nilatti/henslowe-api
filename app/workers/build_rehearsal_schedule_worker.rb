class BuildRehearsalScheduleWorker
  include SuckerPunch::Job

  def perform(break_length, days_of_week, default_user_ids, end_date, end_time, production_id, time_between_breaks, start_date, start_time)
    break_length = break_length.to_i
    production_id = production_id.to_i
    time_between_breaks = time_between_breaks.to_i
    days_of_week = days_of_week.split(',')
    default_users = default_user_ids.split(',')
    BuildRehearsalScheduleBlocks.new(break_length: break_length, days_of_week: days_of_week, default_user_ids: default_user_ids, end_date: end_date, end_time: end_time, production_id: production_id, time_between_breaks: time_between_breaks, start_date: start_date, start_time: start_time).run
  end
end
