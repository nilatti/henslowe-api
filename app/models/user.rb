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
  has_many :character_group, through: :jobs
  has_many :on_stages, through: :character_group
  has_many :french_scenes, through: :on_stages
  has_many :productions, through: :jobs
  has_many :theaters, through: :jobs
  has_many :specializations, through: :jobs
  has_and_belongs_to_many :rehearsals

  default_scope {order(:last_name, :first_name, :email)}

  before_save :update_subscription_status

  def self.authenticate(email, password)
    user = User.find_for_authentication(email: email)
    user&.valid_password?(password) ? user : nil
  end

  def self.from_omniauth(auth)
    user = User.includes(:jobs).find_or_create_by(email: auth['info']['email']) do |user|
      user.provider = auth['provider']
      user.uid = auth['uid']
      user.email = auth['info']['email']
      user.first_name = auth['info']['first_name']
      user.last_name = auth['info']['last_name']
    end
    return user
  end

  def castings_for_production(production)
    jobs = production_jobs(production)
    acting_jobs = jobs.select { |job| job.specialization.title == "Actor"}
    return acting_jobs.map(&:character).sort {|a, b| a.name <=> b.name}
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
        french_scenes[on_stage.french_scene].push(report_string)
      end
    end
    extras.each do |extra|
      french_scenes[extra.french_scene].push(extra.name)
    end
    return french_scenes #this is a hash of french scenes (keys), with an array of characters as the values
  end

  def is_actor?(production)
    unless self.characters.size == 0
      return true
    end
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
    self_user_theaters = self.jobs.map {|job| job.theater.id}.to_set
    target_user_theaters = target_user.jobs.map {|job| job.theater.id}.to_set
    theaters_overlap = self_user_theaters & target_user_theaters
    if theaters_overlap.size == 0
      return "none"
    end
    # check for current jobs for both users
    target_user_current_jobs = target_user.jobs.select {|job| job.end_date < Date.today + 1.month }
    self_user_current_jobs = self.jobs.select {|job| job.end_date < Date.today + 1.month }
    if target_user_current_jobs.size == 0 || self_user_current_jobs.size == 0
      return "past peer"
    end
    theater_admin = theaters_overlap.select {|theater_id| self.theater_admin?(Theater.find(theater_id))}
    if theater_admin.size > 0
      return "theater admin"
    end
    self_user_productions = self.jobs.map {|job| job.production.id}.to_set
    target_user_productions = target_user.jobs.map {|job| job.production.id}.to_set
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

  def name
  	"#{first_name} #{last_name}"
  end
  def name_and_production_job_titles(production)
    "#{name} (#{production_job_titles(production).join(", ")})"
  end
  def production_admin?(production)
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

  def update_subscription_status
    Stripe.api_key = ENV['STRIPE_SECRET_KEY']
    subscriptions = Stripe::Subscription.list({customer: self.stripe_customer_id}).data
    subscriptions.sort_by(&:current_period_end)
    self.subscription_status = subscriptions.last.status
    self.subscription_end_date = DateTime.strptime("#{subscriptions.last.current_period_end}",'%s')
  end
end
