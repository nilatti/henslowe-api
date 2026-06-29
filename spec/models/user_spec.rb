require 'rails_helper'

RSpec.describe User, type: :model do
  it "has a valid factory" do
    expect(build(:user)).to be_valid
  end

  let(:user) { build(:user) }
  describe "ActiveRecord associations" do
    it { expect(user).to have_many(:conflicts) }
    it { expect(user).to have_many(:entrance_exits) }
    it { expect(user).to have_many(:jobs).dependent(:destroy) }
    it { expect(user).to have_many(:characters).through(:jobs) }
    it { expect(user).to have_many(:on_stages).through(:characters) }
    it { expect(user).to have_many(:french_scenes).through(:on_stages) }
    it { expect(user).to have_many(:productions).through(:jobs) }
    it { expect(user).to have_many(:theaters).through(:jobs) }
    it { expect(user).to have_many(:specializations).through(:jobs) }
  end

  describe "it validates data" do
    it { expect(user).to validate_presence_of(:email)}
    it { expect(user).to validate_presence_of(:first_name)}
    it { expect(user).to validate_presence_of(:last_name)}
    it { expect(user).to validate_uniqueness_of(:email).case_insensitive}

    it "allows a user to be created without a phone number" do
      expect(build(:user, phone_number: nil)).to be_valid
    end
  end

  describe "make_new_fake_theater callback" do
    before { MakeFakeTheaterWorker.clear }

    it "enqueues MakeFakeTheaterWorker when provider is present" do
      create(:user, provider: 'google_oauth2', uid: '123456')
      expect(MakeFakeTheaterWorker.jobs.size).to eq(1)
    end

    it "does not enqueue MakeFakeTheaterWorker for admin-created users without provider" do
      create(:user, provider: nil)
      expect(MakeFakeTheaterWorker.jobs.size).to eq(0)
    end

    it "does not enqueue MakeFakeTheaterWorker for fake users" do
      create(:user, fake: true, provider: 'fake', uid: 'fake-test')
      expect(MakeFakeTheaterWorker.jobs.size).to eq(0)
    end
  end

  describe "french_scenes_for_production" do
    let!(:user) { create(:user) }
    let!(:production) { create(:production) }
    let!(:character) { create(:character) }
    let!(:actor_job) { create(:job, :actor_job, user: user, production: production, character: character) }

    it "appends (offstage) to the report string for offstage on_stages" do
      on_stage = create(:on_stage, character: character, offstage: true)
      result = user.french_scenes_for_production(production)
      expect(result[on_stage.french_scene]).to include("#{character.name}(offstage)")
    end

    it "does not append (offstage) for onstage on_stages" do
      on_stage = create(:on_stage, character: character, offstage: false)
      result = user.french_scenes_for_production(production)
      expect(result[on_stage.french_scene].first).not_to include("(offstage)")
    end

    it "appends * for nonspeaking and (offstage) for offstage independently" do
      on_stage = create(:on_stage, character: character, nonspeaking: true, offstage: true)
      result = user.french_scenes_for_production(production)
      expect(result[on_stage.french_scene]).to include("#{character.name}*(offstage)")
    end

    context "with character group jobs" do
      let!(:character_group) { create(:character_group) }
      let!(:group_job) { create(:job, :actor_job, user: user, production: production, character_group: character_group) }

      it "includes character group name for on_stages the user appears in via group" do
        on_stage = create(:on_stage, character_group: character_group)
        result = user.french_scenes_for_production(production)
        expect(result[on_stage.french_scene]).to include(character_group.name)
      end

      it "does not include character group on_stages from other productions" do
        other_production = create(:production)
        create(:on_stage, character_group: character_group)
        result = user.french_scenes_for_production(other_production)
        expect(result.values.flatten).not_to include(character_group.name)
      end
    end
  end

  describe "#jobs_overlap" do
    let(:theater) { create(:theater) }
    let(:production) { create(:production, theater: theater) }
    let(:actor_spec) { create(:specialization, :actor) }
    let(:prod_admin_spec) { create(:specialization, :director) }
    let(:theater_admin_spec) { create(:specialization, :theater_admin) }

    let(:viewer) { create(:user, :paid) }
    let(:target) { create(:user) }

    def active_job(user, **opts)
      create(:job, user: user, theater: theater, production: production, specialization: actor_spec, end_date: 1.year.from_now, **opts)
    end

    def expired_job(user, **opts)
      create(:job, user: user, theater: theater, production: production, specialization: actor_spec, start_date: 2.years.ago, end_date: 1.year.ago, **opts)
    end

    context "when viewer is a superadmin" do
      it "returns 'superadmin'" do
        viewer.update(role: :superadmin)
        expect(viewer.jobs_overlap(target)).to eq("superadmin")
      end
    end

    context "when viewer is the target user" do
      it "returns 'self'" do
        expect(viewer.jobs_overlap(viewer)).to eq("self")
      end
    end

    context "when users share no theater" do
      it "returns 'none'" do
        other_theater = create(:theater)
        other_production = create(:production, theater: other_theater)
        active_job(viewer)
        create(:job, user: target, theater: other_theater, production: other_production, specialization: actor_spec, end_date: 1.year.from_now)
        expect(viewer.jobs_overlap(target)).to eq("none")
      end
    end

    context "nil-safety" do
      it "does not raise when a job has a nil theater" do
        create(:job, user: viewer, theater: nil, production: production, specialization: actor_spec, end_date: 1.year.from_now)
        active_job(target)
        expect { viewer.jobs_overlap(target) }.not_to raise_error
      end

      it "does not raise when a job has a nil production" do
        create(:job, user: viewer, theater: theater, production: nil, specialization: actor_spec, end_date: 1.year.from_now)
        active_job(target)
        expect { viewer.jobs_overlap(target) }.not_to raise_error
      end

      it "does not raise when a job has a nil end_date" do
        create(:job, user: viewer, theater: theater, production: production, specialization: actor_spec, end_date: nil)
        active_job(target)
        expect { viewer.jobs_overlap(target) }.not_to raise_error
      end
    end

    context "end_date / current job logic" do
      before { active_job(target) }

      it "treats a nil end_date job as current (indefinite, e.g. executive director)" do
        create(:job, user: viewer, theater: theater, production: production, specialization: actor_spec, end_date: nil)
        expect(viewer.jobs_overlap(target)).not_to eq("past peer")
      end

      it "treats a job ending today as current" do
        create(:job, user: viewer, theater: theater, production: production, specialization: actor_spec, end_date: Date.today)
        expect(viewer.jobs_overlap(target)).not_to eq("past peer")
      end

      it "treats a job with a past end_date as not current, returning 'past peer'" do
        expired_job(viewer)
        expect(viewer.jobs_overlap(target)).to eq("past peer")
      end
    end

    context "overlap levels with shared active jobs" do
      before { active_job(target) }

      it "returns 'theater admin' when viewer is a theater admin in the shared theater" do
        create(:job, user: viewer, theater: theater, production: production, specialization: theater_admin_spec, end_date: 1.year.from_now)
        expect(viewer.jobs_overlap(target)).to eq("theater admin")
      end

      it "returns 'production admin' when viewer is a production admin on the shared production" do
        create(:job, user: viewer, theater: theater, production: production, specialization: prod_admin_spec, end_date: 1.year.from_now)
        expect(viewer.jobs_overlap(target)).to eq("production admin")
      end

      it "returns 'production peer' when viewer shares the production without an admin role" do
        active_job(viewer)
        expect(viewer.jobs_overlap(target)).to eq("production peer")
      end

      it "returns 'theater peer' when viewer shares the theater but is in a different production" do
        other_production = create(:production, theater: theater)
        create(:job, user: viewer, theater: theater, production: other_production, specialization: actor_spec, end_date: 1.year.from_now)
        expect(viewer.jobs_overlap(target)).to eq("theater peer")
      end
    end
  end

  describe "#visible_users" do
    let(:theater) { create(:theater) }
    let(:production) { create(:production, theater: theater) }
    let(:actor_spec) { create(:specialization, :actor) }
    let(:viewer) { create(:user) }

    context "when viewer is a superadmin" do
      before { viewer.update(role: :superadmin) }

      it "returns all users" do
        others = create_list(:user, 3)
        result = viewer.visible_users
        expect(result).to include(viewer, *others)
      end
    end

    context "when viewer has a theater-level job (production_id nil)" do
      let!(:theater_job) { create(:job, user: viewer, theater: theater, production: nil, specialization: actor_spec, end_date: nil) }

      it "includes users with theater jobs at the same theater" do
        peer = create(:user)
        create(:job, user: peer, theater: theater, production: nil, specialization: actor_spec, end_date: nil)
        expect(viewer.visible_users).to include(peer)
      end

      it "includes users with production jobs on that theater's productions" do
        prod_user = create(:user)
        create(:job, user: prod_user, production: production, specialization: actor_spec, end_date: nil)
        expect(viewer.visible_users).to include(prod_user)
      end

      it "excludes users with theater jobs at a different theater" do
        other_theater = create(:theater)
        other_user = create(:user)
        create(:job, user: other_user, theater: other_theater, production: nil, specialization: actor_spec, end_date: nil)
        expect(viewer.visible_users).not_to include(other_user)
      end

      it "excludes users with production jobs on unrelated productions" do
        other_production = create(:production, theater: create(:theater))
        other_user = create(:user)
        create(:job, user: other_user, production: other_production, specialization: actor_spec, end_date: nil)
        expect(viewer.visible_users).not_to include(other_user)
      end

      it "always includes self" do
        expect(viewer.visible_users).to include(viewer)
      end
    end

    context "when viewer has a production job" do
      let!(:production_job) { create(:job, user: viewer, production: production, specialization: actor_spec, end_date: nil) }

      it "includes users with theater jobs at the production's theater" do
        theater_user = create(:user)
        create(:job, user: theater_user, theater: theater, production: nil, specialization: actor_spec, end_date: nil)
        expect(viewer.visible_users).to include(theater_user)
      end

      it "includes users with production jobs on the same production" do
        peer = create(:user)
        create(:job, user: peer, production: production, specialization: actor_spec, end_date: nil)
        expect(viewer.visible_users).to include(peer)
      end

      it "excludes users with production jobs on different productions" do
        other_production = create(:production, theater: theater)
        other_user = create(:user)
        create(:job, user: other_user, production: other_production, specialization: actor_spec, end_date: nil)
        expect(viewer.visible_users).not_to include(other_user)
      end

      it "excludes users with theater jobs at unrelated theaters" do
        other_theater = create(:theater)
        other_user = create(:user)
        create(:job, user: other_user, theater: other_theater, production: nil, specialization: actor_spec, end_date: nil)
        expect(viewer.visible_users).not_to include(other_user)
      end

      it "always includes self" do
        expect(viewer.visible_users).to include(viewer)
      end
    end

    context "when viewer has no jobs" do
      it "returns only self" do
        create_list(:user, 3)
        result = viewer.visible_users
        expect(result.map(&:id)).to eq([viewer.id])
      end
    end

    context "when viewer has both a theater job and a production job" do
      let(:other_theater) { create(:theater) }
      let(:other_production) { create(:production, theater: other_theater) }
      let!(:theater_job) { create(:job, user: viewer, theater: theater, production: nil, specialization: actor_spec, end_date: nil) }
      let!(:production_job) { create(:job, user: viewer, production: other_production, specialization: actor_spec, end_date: nil) }

      it "combines visibility from both contexts" do
        theater_peer = create(:user)
        create(:job, user: theater_peer, theater: theater, production: nil, specialization: actor_spec, end_date: nil)
        production_peer = create(:user)
        create(:job, user: production_peer, production: other_production, specialization: actor_spec, end_date: nil)
        result_ids = viewer.visible_users.map(&:id)
        expect(result_ids).to include(theater_peer.id, production_peer.id)
      end
    end
  end

  it "it sorts users" do
    user2 = create(:user, last_name: "Lebowski", first_name: "Dude", email: "dude@test.com")
    user3 = create(:user, last_name: "Lebowski", first_name: "John", email: "john@test.com")
    user1 = create(:user, last_name: "Adams", first_name: "John", email: "jadams@test.com")
    user5 = create(:user, last_name: "Sanders", first_name: "Bernie", email: "bernie@test.com")
    user4 = create(:user, last_name: "Lebowski", first_name: "John", email: "lou@test.com")
    users = [user1, user2, user3, user4, user5]
    expect(User.all).to match_array(users)
  end

  describe '#has_active_subscription?' do
    it 'returns true when subscription_status is active' do
      expect(build(:user, subscription_status: 'active').has_active_subscription?).to be true
    end

    it 'returns false when subscription_status is never subscribed' do
      expect(build(:user, subscription_status: 'never subscribed').has_active_subscription?).to be false
    end

    it 'returns false when subscription_status is canceled' do
      expect(build(:user, subscription_status: 'canceled').has_active_subscription?).to be false
    end

    it 'returns false when subscription_status is nil' do
      expect(build(:user, subscription_status: nil).has_active_subscription?).to be false
    end

    it 'returns true when paid_override is true regardless of subscription_status' do
      expect(build(:user, paid_override: true, subscription_status: 'never subscribed').has_active_subscription?).to be true
    end

    it 'returns true when paid_override is true and subscription_status is nil' do
      expect(build(:user, paid_override: true, subscription_status: nil).has_active_subscription?).to be true
    end

    it 'returns false when paid_override is false and subscription_status is not active' do
      expect(build(:user, paid_override: false, subscription_status: 'canceled').has_active_subscription?).to be false
    end
  end

end

#   default_scope {order(:last_name, :first_name, :email)}
# end
