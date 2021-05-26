# the problem is in block length -- it's not passing from the form, but it really doesn't have to because it is just rehearsal time + break time
class BuildRehearsalScheduleBlocks
  def initialize(break_length:, days_of_week:, default_user_ids:, end_date:, end_time:, production_id:, time_between_breaks:, start_date:, start_time:)
    @break_length = break_length
    @days_of_week = days_of_week
    @default_user_ids = default_user_ids
    @end_date = end_date
    @end_time = end_time
    @production_id = production_id
    @start_date = start_date
    @start_time = start_time
    @rehearsal_blocks = []
    @time_between_breaks = time_between_breaks #time_between_breaks is the time from the end of one break to the beginning of the next break, also known as the time when rehearsal is happening.
    @block_length = @break_length + @time_between_breaks
  end

  def run
    users = @default_user_ids.map {|uid| User.find(uid)}
    @rehearsal_blocks = build_recurring_rehearsals(
      block_length: @block_length,
      break_length: @break_length,
      days_of_week: @days_of_week,
      default_users: users,
      end_date: @end_date,
      end_time: @end_time,
      start_date: @start_date,
      start_time: @start_time,
      time_between_breaks: @time_between_breaks
    )
    # puts "about to import rehearsal"
    # # imports = Rehearsal.import! @rehearsal_blocks
    # puts "failed"
    # puts imports.failed_instances
    # puts "success"
    # puts imports.num_inserts

  end
  def build_recurring_rehearsals(
    block_length:,
    break_length:,
    days_of_week:,
    default_users:,
    end_date:,
    end_time:,
    start_date:,
    start_time:,
    time_between_breaks:
  ) #block length should be in minutes
    blocks = build_rehearsal_blocks(block_length: block_length, break_length: break_length, end_time: end_time, start_time: start_time, time_between_breaks: time_between_breaks)
    days = build_rehearsal_days(days_of_week: days_of_week, end_date: end_date, start_date: start_date)
    rehearsal_blocks_array = []
    days.each do |day|
      blocks.each do |block|
        r = Rehearsal.new
        r.end_time = Time.zone.parse("#{day.strftime('%F')} #{block[:end_time].strftime('%T')}")
        r.production_id = @production_id
        r.notes = block[:notes]
        r.start_time = Time.zone.parse("#{day.strftime('%F')} #{block[:start_time].strftime('%T')}")
        r.save
        r.users = default_users
        r.save
      end
    end
  end

  def build_rehearsal_blocks(block_length:, break_length:, end_time:, start_time:, time_between_breaks:)
    rehearsal_blocks = []
    block_start_time = Time.zone.parse(start_time)
    next_break = block_start_time + time_between_breaks.minutes
    end_time = Time.zone.parse(end_time)
    until block_start_time >= end_time
      block = {
        end_time: Time.new,
        notes: 'rehearsal',
        start_time: Time.new,
      }
      break_obj = {
        end_time: Time.new,
        notes: 'break',
        start_time: Time.new,
      }
      block[:start_time] = block_start_time
      if block_start_time < next_break
        block[:end_time] = block[:start_time] + block_length.minutes
        if block[:end_time] > next_break
          block[:end_time] = next_break
        end
        block[:notes] = 'rehearsing'
        block_start_time = block[:end_time]
        rehearsal_blocks << block
      else
        break_obj[:start_time] = next_break
        break_obj[:end_time] = next_break + break_length.minutes
        next_break = break_obj[:end_time] + time_between_breaks.minutes
        block_start_time = break_obj[:end_time]
      end
    end
    return rehearsal_blocks
  end

  def build_rehearsal_days(days_of_week:, end_date:, start_date:)
    days_arr = days_of_week.flatten

    days = days_arr.each {|day| day.to_sym}
    start_on = Date.parse(start_date)
    end_on = Date.parse(end_date)
    schedule = Montrose.every(:week, starts: start_on, until: end_on).on(days)
  end
end
