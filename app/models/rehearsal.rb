class Rehearsal < ApplicationRecord
  belongs_to :space, optional: true
  belongs_to :production
  has_and_belongs_to_many :acts
  has_and_belongs_to_many :scenes
  has_and_belongs_to_many :french_scenes
  has_and_belongs_to_many :users
  has_many :conflicts, dependent: :destroy
  has_many :rehearsal_invites, dependent: :destroy
  # add check on time start before end

  def calendar_summary
    play_title = production.play&.title
    play_title.present? ? "#{play_title}: #{title.presence || 'Rehearsal'}" : (title.presence || 'Rehearsal')
  end

  def calendar_description
    [text_unit_content, notes].reject(&:blank?).join("\n")
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
