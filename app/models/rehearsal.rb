class Rehearsal < ApplicationRecord
  belongs_to :space, optional: true
  belongs_to :production
  # Play order everywhere a rehearsal's content is read (API, schedules,
  # calendar invites). Each model's own default scope sorts by its position
  # within its parent alone, which would interleave units from different acts/scenes.
  has_and_belongs_to_many :acts, -> { reorder(:position) }
  has_and_belongs_to_many :scenes, -> { joins(:act).reorder('acts.position', 'scenes.position') }
  has_and_belongs_to_many :french_scenes,
    -> { joins(scene: :act).reorder('acts.position', 'scenes.position', 'french_scenes.position') }
  # The calendar description lists everyone called, so changing the call list
  # counts as changing the rehearsal: the next publish resends to everyone
  # already invited, not just the people added or removed.
  has_and_belongs_to_many :users, after_add: :touch_for_call_list_change, after_remove: :touch_for_call_list_change
  has_many :conflicts, dependent: :destroy
  has_many :rehearsal_invites, dependent: :destroy
  # add check on time start before end

  def calendar_summary
    play_title = production.play&.title
    play_title.present? ? "#{play_title}: #{title.presence || 'Rehearsal'}" : (title.presence || 'Rehearsal')
  end

  def calendar_description
    [text_unit_content, call_list_content, notes].reject(&:blank?).join("\n")
  end

  def calendar_location
    return nil unless space

    [space.name, space.full_address].reject(&:blank?).join(', ')
  end

  def text_unit_content
    [
      acts.map { |a| self.class.with_page_range(a.heading, a) },
      scenes.map { |s| self.class.with_page_range(s.pretty_name, s) },
      french_scenes.map { |fs| self.class.with_page_range(fs.pretty_name, fs) },
    ].flatten.reject(&:blank?).join(", ")
  end

  # Everyone called (actors and staff), alphabetized by last name, named the
  # way the frontend's buildUserName does.
  def call_list_content
    return nil if users.empty?

    called = users.sort_by { |u| [u.last_name.to_s.downcase, u.first_name.to_s.downcase, u.email.to_s.downcase] }
    "Called: #{called.map { |u| "#{u.preferred_name.presence || u.first_name} #{u.last_name}" }.join(', ')}"
  end

  def touch_for_call_list_change(_user)
    touch if persisted?
  end

  def self.with_page_range(name, item)
    return name if name.blank? || item.start_page.nil? || item.end_page.nil?

    item.start_page == item.end_page ? "#{name} (p. #{item.start_page})" : "#{name} (pp. #{item.start_page}–#{item.end_page})"
  end

  def sync_conflicts
    return unless start_time && end_time

    if space_id
      conflicts.where(user_id: nil).where.not(space_id: space_id).destroy_all
      c = conflicts.find_or_initialize_by(space_id: space_id, user_id: nil)
      c.start_time = start_time
      c.end_time = end_time
      c.category = 'rehearsal'
      c.save!
    else
      conflicts.where(user_id: nil).destroy_all
    end

    current_user_ids = users.pluck(:id)
    conflicts.where.not(user_id: nil).where.not(user_id: current_user_ids).destroy_all
    current_user_ids.each do |uid|
      c = conflicts.find_or_initialize_by(user_id: uid, space_id: nil)
      c.start_time = start_time
      c.end_time = end_time
      c.category = 'rehearsal'
      c.save!
    end
  end
end
