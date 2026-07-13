require 'rails_helper'

RSpec.describe Job, type: :model do
  it "has a valid factory" do
    expect(build(:job)).to be_valid
  end

  let(:job) { build(:job) }

  describe "ActiveModel validations" do
    it "checks that start date is before end date" do
      job_with_bad_dates = build(:job, end_date: Faker::Date.between(from: 2.years.ago, to: 1.year.ago), start_date: Faker::Date.between(from: 1.year.ago, to: 3.months.ago))
      job_with_bad_dates.valid?
      expect(job_with_bad_dates.errors[:end_date]).to include("can't be before start date")

      job.valid?
      expect(job).to be_valid
    end
  end

  describe "dream theater validation (on create)" do
    let!(:dream_theater) { create(:theater, :fake) }
    let!(:real_theater)  { create(:theater) }
    let!(:real_user)     { create(:user) }
    let!(:fake_user)     { create(:user, :fake) }
    let!(:production)    { create(:production, theater: dream_theater) }

    it "allows fake users to be cast in dream theater productions" do
      job = build(:job, user: fake_user, production: production, theater: nil,
                        specialization: create(:specialization, :actor))
      expect(job).to be_valid
    end

    it "blocks real users from being cast in dream theater productions" do
      job = build(:job, user: real_user, production: production, theater: nil,
                        specialization: create(:specialization, :actor))
      expect(job).not_to be_valid
      expect(job.errors[:base]).to include("Dream theater productions cannot have real users as cast or staff")
    end

    it "blocks real users from staff jobs at dream theater productions" do
      job = build(:job, user: real_user, production: production, theater: nil,
                        specialization: create(:specialization, :director))
      expect(job).not_to be_valid
      expect(job.errors[:base]).to include("Dream theater productions cannot have real users as cast or staff")
    end

    it "allows the Theater Admin job at theater level (the owner's job)" do
      job = build(:job, user: real_user, theater: dream_theater, production: nil,
                        specialization: create(:specialization, :theater_admin))
      expect(job).to be_valid
    end

    it "does not fire for real theaters" do
      job = build(:job, user: real_user, theater: real_theater, production: nil,
                        specialization: create(:specialization, :actor))
      expect(job.errors[:base]).not_to include("Dream theater productions cannot have real users as cast or staff")
    end
  end

  describe "payment validation (on create) — all roles except actor/auditioner" do
    let!(:real_theater)      { create(:theater) }
    let!(:dream_theater)     { create(:theater, :fake) }
    let!(:paid_user)         { create(:user, :paid) }
    let!(:override_user)     { create(:user, :paid_override) }
    let!(:unpaid_user)       { create(:user) }
    let!(:fake_user)         { create(:user, :fake) }
    let!(:production)        { create(:production, theater: real_theater) }
    let!(:director_spec)     { create(:specialization, :director) }
    let!(:actor_spec)        { create(:specialization, :actor) }
    let!(:auditioner_spec)   { create(:specialization, :auditioner) }
    let!(:stage_mgr_spec)    { create(:specialization, title: 'Stage Manager', production_admin: false) }

    it "allows a paid user in any paid role" do
      job = build(:job, user: paid_user, production: production, theater: nil,
                        specialization: director_spec)
      expect(job).to be_valid
    end

    it "allows a user with paid_override in any paid role" do
      job = build(:job, user: override_user, production: production, theater: nil,
                        specialization: director_spec)
      expect(job).to be_valid
    end

    it "blocks an unpaid user from an admin role" do
      job = build(:job, user: unpaid_user, production: production, theater: nil,
                        specialization: director_spec)
      expect(job).not_to be_valid
      expect(job.errors[:base]).to include("payment_required")
    end

    it "blocks an unpaid user from a non-admin, non-free role (e.g. Stage Manager)" do
      job = build(:job, user: unpaid_user, production: production, theater: nil,
                        specialization: stage_mgr_spec)
      expect(job).not_to be_valid
      expect(job.errors[:base]).to include("payment_required")
    end

    it "does not apply to actor roles" do
      job = build(:job, user: unpaid_user, production: production, theater: nil,
                        specialization: actor_spec)
      expect(job.errors[:base]).not_to include("payment_required")
    end

    it "does not apply to auditioner roles" do
      job = build(:job, user: unpaid_user, production: production, theater: nil,
                        specialization: auditioner_spec)
      expect(job.errors[:base]).not_to include("payment_required")
    end

    it "does not apply to fake users" do
      job = build(:job, user: fake_user, production: production, theater: nil,
                        specialization: director_spec)
      expect(job.errors[:base]).not_to include("payment_required")
    end

    it "does not apply at dream theaters (exempt)" do
      job = build(:job, user: paid_user, theater: dream_theater, production: nil,
                        specialization: create(:specialization, :theater_admin))
      expect(job.errors[:base]).not_to include("payment_required")
    end
  end

  describe "theater-sponsored bypass (on create)" do
    let!(:sponsoring_theater) { create(:theater, subscription_status: 'active') }
    let!(:unsponsored_theater) { create(:theater) }
    let!(:unpaid_user) { create(:user) }
    let!(:director_spec) { create(:specialization, :director) }

    it "allows an unpaid user when theater_sponsored and the theater has an active subscription" do
      job = build(:job, user: unpaid_user, theater: sponsoring_theater, production: nil,
                        specialization: director_spec, theater_sponsored: true)
      expect(job).to be_valid
    end

    it "still blocks an unpaid user when theater_sponsored but the theater isn't subscribed" do
      job = build(:job, user: unpaid_user, theater: unsponsored_theater, production: nil,
                        specialization: director_spec, theater_sponsored: true)
      expect(job).not_to be_valid
      expect(job.errors[:base]).to include("payment_required")
    end

    it "still blocks an unpaid user at a subscribed theater when the job isn't marked theater_sponsored" do
      job = build(:job, user: unpaid_user, theater: sponsoring_theater, production: nil,
                        specialization: director_spec, theater_sponsored: false)
      expect(job).not_to be_valid
      expect(job.errors[:base]).to include("payment_required")
    end

    it "resolves sponsorship via the production's theater for production-scoped jobs" do
      production = create(:production, theater: sponsoring_theater)
      job = build(:job, user: unpaid_user, theater: nil, production: production,
                        specialization: director_spec, theater_sponsored: true)
      expect(job).to be_valid
    end
  end

  describe "ActiveRecord associations" do
    it { expect(job).to belong_to(:character).optional }
    it { expect(job).to belong_to(:production).optional }
    it { expect(job).to belong_to(:specialization).optional }
    it { expect(job).to belong_to(:theater).optional }
    it { expect(job).to belong_to(:user).optional }
  end
  it "scopes function (basic)" do
    production             = build(:production)
    specialization         = build(:specialization)
    actor_specialization   = build(:specialization, title: 'Actor')
    auditioner_specialization = build(:specialization, title: 'Auditioner')
    # Non-free spec used by scope-filler jobs so they don't pollute Job.actor.
    non_free_spec          = create(:specialization, title: 'Stage Manager')
    theater                = build(:theater)
    paid                   = create(:user, :paid)   # shared paid user for non-free scope jobs
    user                   = create(:user, :paid)   # dedicated user for the user-scope assertion

    actor_jobs             = create_list(:job, 3, specialization: actor_specialization)
    auditioner_jobs        = create_list(:job, 3, specialization: auditioner_specialization)
    actor_and_auditioner_jobs = actor_jobs + auditioner_jobs
    production_jobs        = create_list(:job, 3, production: production, specialization: non_free_spec, user: paid)
    specialization_jobs    = create_list(:job, 3, specialization: specialization, user: paid)
    theater_jobs           = create_list(:job, 3, theater: theater, specialization: non_free_spec, user: paid)
    user_jobs              = create_list(:job, 3, user: user, specialization: non_free_spec)

    expect(Job.specialization(specialization.id)).to match_array(specialization_jobs)
    expect(Job.theater(theater.id)).to match_array(theater_jobs)
    expect(Job.user(user.id)).to match_array(user_jobs)
    expect(Job.production(production.id)).to match_array(production_jobs)
    expect(Job.actor).to match_array(actor_jobs)
    expect(Job.actor_or_auditioner).to match_array(actor_and_auditioner_jobs)
  end

  it "scopes function (complex)" do
    production = build(:production)
    theater = build(:theater)
    actor_specialization = build(:specialization, title: 'Actor')
    auditioner_specialization = build(:specialization, title: 'Auditioner')
    actor_jobs_for_production = create_list(:job, 3, specialization: actor_specialization, production: production)
    auditioner_jobs_for_production = create_list(:job, 3, specialization: auditioner_specialization, production: production)
    actor_jobs_for_theater = create_list(:job, 3, specialization: actor_specialization, theater: theater)
    auditioner_jobs_for_theater = create_list(:job, 3, specialization: auditioner_specialization, theater: theater)
    expect(Job.actor_for_production(production.id)).to match_array(actor_jobs_for_production)
    expect(Job.actor_or_auditioner_for_production(production.id)).to match_array(actor_jobs_for_production + auditioner_jobs_for_production)
    expect(Job.actor_or_auditioner_for_theater(theater.id)).to match_array(actor_jobs_for_theater + auditioner_jobs_for_theater)
  end
end
