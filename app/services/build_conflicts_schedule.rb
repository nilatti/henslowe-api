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
    user_id:,
    time_zone: nil
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
    @time_zone = ActiveSupport::TimeZone.new(time_zone.to_s) || ActiveSupport::TimeZone['UTC']
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
    ActiveRecord::Base.connection_pool.with_connection do
      Conflict.import @conflicts
    end
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
        # Resolve per-day so patterns spanning a DST transition get the correct
        # standard/daylight offset for each individual occurrence, not one offset
        # fixed at creation time and reused for the whole date range.
        c.end_time = @time_zone.parse("#{day.strftime('%F')} #{end_time}").utc
        if user_id
          c.user = User.find(user_id)
        elsif space_id
          c.space = Space.find(space_id)
        end
        c.regular = true
        c.start_time = @time_zone.parse("#{day.strftime('%F')} #{start_time}").utc
        conflicts_array << c
    end
    return conflicts_array
  end

  def build_conflict_days(days_of_week: @days_of_week, start_date: @start_date, end_date: @end_date)
    days_arr = days_of_week.flatten
    days = days_arr.map { |day| day.downcase.to_sym }
    start_on = start_date
    end_on = end_date
    schedule = Montrose.every(:week, starts: start_on, until: end_on).on(days)
  end
end
