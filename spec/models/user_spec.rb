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

  it "it sorts users" do
    user2 = create(:user, last_name: "Lebowski", first_name: "Dude", email: "dude@test.com")
    user3 = create(:user, last_name: "Lebowski", first_name: "John", email: "john@test.com")
    user1 = create(:user, last_name: "Adams", first_name: "John", email: "jadams@test.com")
    user5 = create(:user, last_name: "Sanders", first_name: "Bernie", email: "bernie@test.com")
    user4 = create(:user, last_name: "Lebowski", first_name: "John", email: "lou@test.com")
    users = [user1, user2, user3, user4, user5]
    expect(User.all).to match_array(users)
  end

end

#   default_scope {order(:last_name, :first_name, :email)}
# end
