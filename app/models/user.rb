class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
    devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  ROLES = %i[superadmin regular]

  validates_uniqueness_of :email, case_sensitive: false
  validates_presence_of :first_name, :last_name, :phone_number, :email
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

  default_scope {order(:last_name, :first_name, :email)}

  def castings_for_production(production)
    jobs = production_jobs(production)
    acting_jobs = jobs.select { |job| job.specialization.title == "Actor"}
    return acting_jobs.map(&:character).sort {|a, b| a.name <=> b.name}
  end

  def is_actor?(production)
    unless self.characters.size == 0
      return true
    end
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
end
