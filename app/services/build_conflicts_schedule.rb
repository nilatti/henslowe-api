class BuildConflictsSchedule
  #tk add space Conflicts
  def initialize(
    category: 'personal',
    conflict_pattern_id: nil,
    days_of_week:,
    end_date: Date.today + 1.year,
    end_time:,
    space_id:,
    start_date: Date.today,
    start_time:,
    user_id:
    )
    @category = category
    @conflicts = []
    @conflict_pattern_id = conflict_pattern_id
    @days_of_week = days_of_week
    @end_date = end_date
    @end_time = end_time
    @space_id = space_id
    @start_date = start_date
    @start_time = start_time
    @user_id = user_id
    end

  def run(
    category: @category,
    conflict_pattern_id: @conflict_pattern_id,
    days_of_week: @days_of_week,
    end_date: @end_date,
    end_time: @end_time,
    space_id: @space_id,
    start_date: @start_date,
    start_time: @start_time,
    user_id: @user_id
    )
    @conflicts = build_conflicts
    Conflict.import @conflicts
  end

  def build_conflicts(
    category: @category,
    conflict_pattern_id: @conflict_pattern_id,
    days_of_week: @days_of_week,
    end_date: @end_date,
    end_time: @end_time,
    space_id: @space_id,
    start_date: @start_date,
    start_time: @start_time,
    user_id: @user_id
  )
    days = build_conflict_days
    conflicts_array = []
    days.each do |day|
        c = Conflict.new
        c.category = category
        if conflict_pattern_id
          c.conflict_pattern = ConflictPattern.find(conflict_pattern_id)
        end
        c.end_time = Time.zone.parse("#{day.strftime('%F')} #{end_time}")
        if user_id
          c.user = User.find(user_id)
        end
        c.regular = true
        if space_id
          c.space = Space.find(space_id)
        end
        c.start_time = Time.zone.parse("#{day.strftime('%F')} #{start_time}")
        conflicts_array << c
    end
    return conflicts_array
  end

  def build_conflict_days(days_of_week: @days_of_week, start_date: @start_date, end_date: @end_date)
    days_arr = days_of_week.flatten
    days = days_arr.each {|day| day.to_sym}
    start_on = start_date
    end_on = end_date
    schedule = Montrose.every(:week, starts: start_on, until: end_on).on(days)
  end
end
