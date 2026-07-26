# Existing ConflictPattern rows predate the time_zone column and were generated
# using a single fixed UTC offset baked in at creation time (wrong for any
# occurrence on the other side of a DST transition). We can't ask the user what
# zone they meant, but we don't have to guess blindly either: every pattern
# already has at least one generated Conflict occurrence whose start_time is a
# real UTC instant, and the pattern's own start_time is the exact wall-clock
# string that instant is supposed to represent. Trying each candidate US zone's
# real (tzinfo-backed) conversion of that instant against the wall-clock string
# tells us exactly which zone was in play — no need to hand-roll DST date math.
namespace :conflict_patterns do
  # No Phoenix-based theater has ever used this app (confirmed) — omitted because it's
  # indistinguishable from a Los Angeles pattern for roughly 8 months of the year: both
  # read -07:00 during Pacific Daylight Time, and every pre-fix occurrence was generated
  # with one fixed offset for the whole year, so a second occurrence sampled from a
  # different season doesn't disambiguate them either (it was generated with that same
  # wrong fixed offset, not the zone's real seasonal one).
  CANDIDATE_TIME_ZONES = %w[
    America/New_York
    America/Chicago
    America/Denver
    America/Los_Angeles
    America/Anchorage
    Pacific/Honolulu
  ].freeze

  FALLBACK_TIME_ZONE = "America/New_York".freeze

  # Most patterns store a bare "HH:MM"; a few legacy rows store a full ISO datetime
  # (e.g. "2022-04-01T04:00:00.000Z") — pull just the time-of-day out of either.
  def bare_time(str)
    s = str.to_s
    (m = s.match(/T(\d{2}:\d{2})/)) ? m[1] : s[0, 5]
  end

  desc "Backfill conflict_patterns.time_zone by reverse-deriving it from already-generated Conflict occurrences"
  task backfill_time_zones: :environment do
    ConflictPattern.where(time_zone: [nil, ""]).find_each do |pattern|
      occurrence = pattern.conflicts.where(regular: true).order(:start_time).first

      unless occurrence
        puts "[skip] ConflictPattern##{pattern.id}: no generated occurrences to derive from, defaulting to #{FALLBACK_TIME_ZONE}"
        pattern.update!(time_zone: FALLBACK_TIME_ZONE)
        next
      end

      matches = CANDIDATE_TIME_ZONES.select do |zone|
        local_start = occurrence.start_time.in_time_zone(zone)
        local_end = occurrence.end_time.in_time_zone(zone)
        bare_time(local_start.strftime("%H:%M")) == bare_time(pattern.start_time) &&
          bare_time(local_end.strftime("%H:%M")) == bare_time(pattern.end_time)
      end

      resolved =
        case matches.size
        when 0
          puts "[warn] ConflictPattern##{pattern.id}: no candidate zone matched occurrence ##{occurrence.id} " \
               "(#{occurrence.start_time.iso8601} UTC vs wall-clock #{pattern.start_time}), defaulting to #{FALLBACK_TIME_ZONE}"
          FALLBACK_TIME_ZONE
        when 1
          matches.first
        else
          puts "[warn] ConflictPattern##{pattern.id}: ambiguous match #{matches} for occurrence ##{occurrence.id}, picking #{matches.first}"
          matches.first
        end

      pattern.update!(time_zone: resolved)
      puts "[ok] ConflictPattern##{pattern.id} -> #{resolved}"
    end
  end

  desc "Regenerate future occurrences for patterns using their (now-backfilled) time_zone; run after backfill_time_zones"
  task regenerate_future_occurrences: :environment do
    today = Date.current

    ConflictPattern.where.not(time_zone: [nil, ""]).find_each do |pattern|
      if pattern.end_date && pattern.end_date < today
        puts "[skip] ConflictPattern##{pattern.id}: pattern already ended on #{pattern.end_date}"
        next
      end

      regen_start = [pattern.start_date, today].max
      deleted = pattern.conflicts.where(regular: true).where("start_time >= ?", Time.current).delete_all

      BuildConflictsSchedule.new(
        category: pattern.category,
        conflict_pattern_id: pattern.id,
        days_of_week: JSON.parse(pattern.days_of_week),
        end_date: pattern.end_date,
        end_time: pattern.end_time,
        space_id: pattern.space_id,
        start_date: regen_start,
        start_time: pattern.start_time,
        user_id: pattern.user_id,
        time_zone: pattern.time_zone
      ).run

      puts "[ok] ConflictPattern##{pattern.id}: deleted #{deleted} future occurrence(s), regenerated with #{pattern.time_zone}"
    end
  end
end
