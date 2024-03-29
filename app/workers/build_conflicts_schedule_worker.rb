class BuildConflictsScheduleWorker
  include SuckerPunch::Job

  def perform(category, conflict_pattern_id, days_of_week, end_date, end_time, space_id, start_date, start_time, user_id)
    days_of_week = days_of_week.split(',')
    if space_id
      space_id = space_id.to_i
    else
      space_id = nil
    end
    user_id = user_id.to_i
    logger.info "starting build conflicts schedule."
    logger.info(start_date)
    logger.info(end_date)
    logger.info('ready to call builder')
    if start_date.nil?
      start_date = Date.today
    end
    if end_date.nil?
      end_date = Date.today + 1.year
    end
    BuildConflictsSchedule.new(
      category: category,
      conflict_pattern_id: conflict_pattern_id,
      days_of_week: days_of_week,
      end_date: end_date,
      end_time: end_time,
      space_id: space_id,
      start_date: start_date,
      start_time: start_time,
      user_id: user_id
    ).run
  end
end
