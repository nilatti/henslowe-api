class User < ApplicationRecord
  ROLES = %i[superadmin regular]

  validates_uniqueness_of :email, case_sensitive: false
  validates_presence_of :first_name, :last_name, :email
  has_many :conflicts, dependent: :destroy
  has_many :conflict_patterns, dependent: :destroy
  has_many :entrance_exits
  has_many :jobs, dependent: :destroy
  has_many :characters, through: :jobs
  has_many :on_stages, through: :characters
  has_many :french_scenes, through: :on_stages
  has_many :productions, through: :jobs
  has_many :theaters, through: :jobs
  has_many :specializations, through: :jobs
  has_and_belongs_to_many :rehearsals

  default_scope {order(:last_name, :first_name, :email)}

  after_create :make_new_fake_theater
  before_save :update_subscription_status

  def self.from_omniauth(auth)
    user = User.includes(:jobs).find_or_create_by(email: auth['info']['email']) do |u|
      u.first_name = auth['info']['first_name']
      u.last_name = auth['info']['last_name']
    end
    user.update(provider: auth['provider'], uid: auth['uid'])
    user
  end

  def castings_for_production(production)
    jobs = production_jobs(production)
    acting_jobs = jobs.select { |job| job.specialization.title == "Actor"}
    return acting_jobs.map(&:character).compact.sort {|a, b| a.name <=> b.name}
  end

  def french_scenes_for_production(production)
    french_scenes = Hash.new { |hash, key| hash[key] = Array.new }
    characters = castings_for_production(production)
    characters.each do |character|
      character.on_stages.each do |on_stage|
        report_string = character.name
        if on_stage.nonspeaking
          report_string += "*"
        end
        if on_stage.offstage
          report_string += "(offstage)"
        end
        french_scenes[on_stage.french_scene].push(report_string)
      end
    end
    character_group_jobs = production_jobs(production).select { |job| job.specialization.title == "Actor" && job.character_group_id.present? }
    character_group_jobs.map(&:character_group).compact.uniq.each do |character_group|
      character_group.on_stages.each do |on_stage|
        french_scenes[on_stage.french_scene].push(character_group.name)
      end
    end
    return french_scenes #this is a hash of french scenes (keys), with an array of characters as the values
  end

  def is_actor?(production)
    unless self.characters.size == 0
      return true
    end
  end

  def visible_users
    return User.all if superadmin?

    my_theater_job_theater_ids = jobs.where.not(theater_id: nil).where(production_id: nil).pluck(:theater_id)
    my_production_job_production_ids = jobs.where.not(production_id: nil).pluck(:production_id)

    visible_ids = [id]

    if my_theater_job_theater_ids.any?
      theater_production_ids = Production.where(theater_id: my_theater_job_theater_ids).pluck(:id)
      visible_ids += User.joins(:jobs).where(jobs: { theater_id: my_theater_job_theater_ids, production_id: nil }).pluck(:id)
      visible_ids += User.joins(:jobs).where(jobs: { production_id: theater_production_ids }).pluck(:id) if theater_production_ids.any?
    end

    if my_production_job_production_ids.any?
      my_production_theater_ids = Production.where(id: my_production_job_production_ids).pluck(:theater_id).compact
      visible_ids += User.joins(:jobs).where(jobs: { theater_id: my_production_theater_ids, production_id: nil }).pluck(:id) if my_production_theater_ids.any?
      visible_ids += User.joins(:jobs).where(jobs: { production_id: my_production_job_production_ids }).pluck(:id)
    end

    User.where(id: visible_ids.uniq)
  end

  def jobs_overlap(target_user)
    if self.superadmin?
      return "superadmin"
    elsif self == target_user
      return "self"
    end
    # determines level of relationship between current user and target user, which then determines the amount of access user has to target user information.
    # current theater admin can see everything
    # current production admin can see a lot of things
    # current production peer can see less than production admin
    # current theater peer can see less than production peer
    # past peers can see limited amount
    self_user_theaters = self.jobs.filter_map {|job| job.theater&.id}.to_set
    target_user_theaters = target_user.jobs.filter_map {|job| job.theater&.id}.to_set
    theaters_overlap = self_user_theaters & target_user_theaters
    if theaters_overlap.size == 0
      return "none"
    end
    # check for current jobs for both users
    target_user_current_jobs = target_user.jobs.select {|job| job.end_date.nil? || job.end_date >= Date.today }
    self_user_current_jobs = self.jobs.select {|job| job.end_date.nil? || job.end_date >= Date.today }
    if target_user_current_jobs.size == 0 || self_user_current_jobs.size == 0
      return "past peer"
    end
    theater_admin = theaters_overlap.select {|theater_id| self.theater_admin?(Theater.find(theater_id))}
    if theater_admin.size > 0
      return "theater admin"
    end
    self_user_productions = self.jobs.filter_map {|job| job.production&.id}.to_set
    target_user_productions = target_user.jobs.filter_map {|job| job.production&.id}.to_set
    productions_overlap = self_user_productions & target_user_productions
    if productions_overlap.size > 0
      production_admin = productions_overlap.select {|production_id| self.production_admin?(Production.find(production_id))}
      if production_admin.size > 0
        return "production admin"
      else
        return "production peer"
      end
    else
      return "theater peer"
    end
  end

  def make_new_fake_theater
    if !self.fake && self.provider.present?
      MakeFakeTheaterWorker.perform_async(self.id)
    end
  rescue RedisClient::CannotConnectError, Redis::CannotConnectError => e
    Rails.logger.warn "Redis unavailable, skipping MakeFakeTheaterWorker: #{e.message}"
  end

  def name
  	"#{first_name} #{last_name}"
  end
  def name_and_production_job_titles(production)
    "#{name} (#{production_job_titles(production).join(", ")})"
  end
  def production_admin?(production)
    return false if production.nil?
    jobs = production_jobs(production)
    admin_jobs = jobs.select { |job| job.specialization.production_admin == true }
    admin_jobs.size > 0 #return true if there are an admin jobs assigned to this user for this production.
  end
  def production_admin_for_play?(play)
    productions = play.productions
    admin = []
    productions.each do |production|
      if production_admin?(production)
        admin << true
      end
    end
    if admin.include?(true)
      return true
    else
      return false
    end
  end
  def production_jobs(production)
    production_jobs = self.jobs.select { |job| job.production_id == production.id }
    return production_jobs
  end
  def production_job_titles(production)
    jobs = production_jobs(production)
    titles = []
    jobs.each do |job|
        titles << job.specialization.title
      end
    return titles
  end
  def regular?
    self.role == "regular"
  end
  def superadmin?
    self.role == "superadmin"
  end
  def theater_admin?(theater)
    return false if theater.nil?
    jobs = theater_jobs(theater)
    admin_jobs = jobs.select { |job| job.specialization.theater_admin == true }
    admin_jobs.size > 0 #return true if there are admin jobs for this user for this theater.
  end
  def theater_admin_for_play?(play)
    productions = play.productions
    admin = []
    productions.each do |production|
      if theater_admin?(production.theater)
        admin << true
      end
    end
    if admin.include?(true)
      return true
    else
      return false
    end
  end
  def theater_jobs(theater)
    self.jobs.select { |job| job.theater_id == theater.id }
  end

  # Allow the user themselves, superadmins, and any production/theater admin
  # who shares a production with the target user to manage that user's conflicts.
  def can_manage_conflicts_for?(other_user)
    return false if other_user.nil?
    return true if id == other_user.id
    return true if superadmin?

    Production.joins(:jobs).where(jobs: { user_id: other_user.id }).distinct.any? do |production|
      production_admin?(production) || theater_admin?(production.theater)
    end
  end

  def has_active_subscription?
    paid_override? || subscription_status == 'active'
  end

  def update_subscription_status
    return unless stripe_customer_id.present? && Stripe.api_key.present?

    subscriptions = Stripe::Subscription.list({ customer: stripe_customer_id }).data
    return if subscriptions.empty?

    # current_period_end moved to SubscriptionItem in Stripe API 2024-09-30+
    latest = subscriptions.max_by { |s| s.items.data.first&.current_period_end || 0 }
    self.subscription_status = latest.status
    period_end = latest.items.data.first&.current_period_end
    self.subscription_end_date = DateTime.strptime(period_end.to_s, '%s') if period_end
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe error syncing subscription for user #{id}: #{e.message}")
  end
end
