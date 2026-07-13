class PublishRehearsalCalendar
  def initialize(production)
    @production = production
  end

  def run
    @production.rehearsals.where('start_time > ?', Time.current).find_each do |rehearsal|
      publish_rehearsal(rehearsal)
    end
  end

  private

  def publish_rehearsal(rehearsal)
    current_ids = rehearsal.user_ids.to_set
    invited_ids = rehearsal.rehearsal_invites.pluck(:user_id).to_set
    # published_at tracks the exact `updated_at` value last published, not a wall-clock
    # timestamp — this is what makes "has this rehearsal changed since publish" a plain
    # equality/inequality check, immune to any timing drift between the two columns.
    changed = rehearsal.published_at.nil? || rehearsal.updated_at > rehearsal.published_at

    additions = current_ids - invited_ids
    removals = invited_ids - current_ids
    resends = changed ? (current_ids & invited_ids) : Set.new

    return if additions.empty? && removals.empty? && resends.empty?

    rehearsal.increment!(:ics_sequence) if resends.any?

    additions.each { |user_id| send_request(rehearsal, user_id) }
    resends.each { |user_id| send_request(rehearsal, user_id) }
    removals.each { |user_id| send_cancel(rehearsal, user_id) }

    rehearsal.update_column(:published_at, rehearsal.updated_at)
  end

  def send_request(rehearsal, user_id)
    invite = rehearsal.rehearsal_invites.find_or_initialize_by(user_id: user_id)
    invite.sent_at = Time.current
    invite.save!
    RehearsalCalendarMailer.invite(rehearsal.id, user_id, rehearsal.ics_sequence).deliver_later
  end

  def send_cancel(rehearsal, user_id)
    RehearsalCalendarMailer.cancel(rehearsal.id, user_id, rehearsal.ics_sequence).deliver_later
    rehearsal.rehearsal_invites.where(user_id: user_id).destroy_all
  end
end
