class BuildConflictsSchedule
  #tk add space Conflicts
  def initialize(
    days_of_week:,
    end_time:,
    start_time:,
    user_id:
    )
    @conflicts = []
    @days_of_week = days_of_week
    @end_time = end_time
    @start_time = start_time
    @user_id = user_id
    end

  def run(days_of_week: @days_of_week, end_time: @end_time, start_time: @start_time, user_id: @user_id)
    @conflicts = build_conflicts(
      days_of_week: days_of_week,
      end_time: end_time,
      start_time: start_time,
      user_id: user_id
    )
    Conflict.import @conflicts
  end

  def build_conflicts(
    days_of_week:,
    end_time:,
    start_time:,
    user_id:
  )
    days = build_conflict_days(days_of_week: days_of_week)
    conflicts_array = []
    days.each do |day|
        c = Conflict.new
        c.end_time = Time.zone.parse("#{day.strftime('%F')} #{end_time}")
        c.user = User.find(user_id)
        c.start_time = Time.zone.parse("#{day.strftime('%F')} #{start_time}")
        conflicts_array << c
    end
    return conflicts_array
  end

  def build_conflict_days(days_of_week:)
    days_arr = days_of_week.flatten
    days = days_arr.each {|day| day.to_sym}
    start_on = Date.today
    end_on = Date.today + 1.year
    schedule = Montrose.every(:week, starts: start_on, until: end_on).on(days)
  end
end
