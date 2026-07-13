class RehearsalCalendarMailer < ApplicationMailer
  def invite(rehearsal_id, user_id, sequence)
    @rehearsal = Rehearsal.includes(:space, production: :theater).find(rehearsal_id)
    @user = User.find(user_id)

    attach_ics(
      method: 'REQUEST',
      uid: ics_uid(@rehearsal.id),
      sequence: sequence,
      summary: rehearsal_summary(@rehearsal),
      description: @rehearsal.notes,
      location: @rehearsal.space&.name,
      start_time: @rehearsal.start_time,
      end_time: @rehearsal.end_time,
    )

    mail(to: @user.email, subject: "Rehearsal: #{rehearsal_summary(@rehearsal)}")
  end

  def cancel(rehearsal_id, user_id, sequence)
    @rehearsal = Rehearsal.includes(:space, production: :theater).find(rehearsal_id)
    @user = User.find(user_id)

    attach_ics(
      method: 'CANCEL',
      uid: ics_uid(@rehearsal.id),
      sequence: sequence,
      summary: rehearsal_summary(@rehearsal),
      description: @rehearsal.notes,
      location: @rehearsal.space&.name,
      start_time: @rehearsal.start_time,
      end_time: @rehearsal.end_time,
      cancelled: true,
    )

    mail(to: @user.email, subject: "Cancelled: #{rehearsal_summary(@rehearsal)}")
  end

  # Used when the underlying Rehearsal record has already been destroyed, so the ICS
  # has to be built from a snapshot captured before deletion rather than loaded fresh.
  def cancel_deleted(snapshot, user_id)
    @snapshot = snapshot.symbolize_keys
    @user = User.find(user_id)

    attach_ics(
      method: 'CANCEL',
      uid: @snapshot[:uid],
      sequence: @snapshot[:sequence],
      summary: @snapshot[:summary],
      description: @snapshot[:description],
      location: @snapshot[:location],
      start_time: @snapshot[:start_time],
      end_time: @snapshot[:end_time],
      cancelled: true,
    )

    mail(to: @user.email, subject: "Cancelled: #{@snapshot[:summary]}", template_name: 'cancel')
  end

  private

  def ics_uid(rehearsal_id)
    "rehearsal-#{rehearsal_id}@henslowescloud.com"
  end

  def rehearsal_summary(rehearsal)
    rehearsal.title.presence || "Rehearsal"
  end

  def attach_ics(method:, uid:, sequence:, summary:, description:, location:, start_time:, end_time:, cancelled: false)
    # Expose the fields views need, since `invite`/`cancel` source them from @rehearsal
    # while `cancel_deleted` sources them from a plain snapshot hash.
    @summary = summary
    @description = description
    @location = location
    @start_time = start_time.to_time
    @end_time = end_time.to_time

    calendar = Icalendar::Calendar.new
    calendar.ip_method = method

    calendar.event do |e|
      e.dtstart = Icalendar::Values::DateTime.new(@start_time.utc, 'tzid' => 'UTC')
      e.dtend = Icalendar::Values::DateTime.new(@end_time.utc, 'tzid' => 'UTC')
      e.summary = summary
      e.description = description if description.present?
      e.location = location if location.present?
      e.uid = uid
      e.sequence = sequence
      e.organizer = "mailto:#{ENV.fetch('MAILER_FROM', 'noreply@henslowescloud.com')}"
      e.attendee = "mailto:#{@user.email}"
      e.status = cancelled ? 'CANCELLED' : 'CONFIRMED'
      e.ip_class = 'PRIVATE'
    end

    attachments['invite.ics'] = {
      mime_type: "text/calendar; method=#{method}; charset=UTF-8",
      content: calendar.to_ical,
    }
  end
end
