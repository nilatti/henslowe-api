require 'rails_helper'

RSpec.describe Invitation, type: :model do
  it "has a valid factory" do
    expect(build(:invitation)).to be_valid
  end

  it "generates a unique token on create" do
    invitation = create(:invitation)
    expect(invitation.token).to be_present
    other = create(:invitation)
    expect(other.token).not_to eq(invitation.token)
  end

  it "defaults to a 14 day expiry" do
    invitation = create(:invitation)
    expect(invitation.expires_at).to be_within(1.minute).of(14.days.from_now)
  end

  it "downcases and strips the email" do
    invitation = create(:invitation, email: "  Some.Person@Example.com  ")
    expect(invitation.email).to eq("some.person@example.com")
  end

  describe "specialization restriction" do
    it "rejects Actor" do
      invitation = build(:invitation, specialization: create(:specialization, :actor))
      expect(invitation).not_to be_valid
      expect(invitation.errors[:specialization]).to be_present
    end

    it "rejects Auditioner" do
      invitation = build(:invitation, specialization: create(:specialization, :auditioner))
      expect(invitation).not_to be_valid
      expect(invitation.errors[:specialization]).to be_present
    end

    it "allows other specializations" do
      invitation = build(:invitation, specialization: create(:specialization, :director))
      expect(invitation).to be_valid
    end
  end

  describe "theater/production exclusivity" do
    it "is invalid with both theater and production" do
      invitation = build(:invitation, theater: create(:theater), production: create(:production))
      expect(invitation).not_to be_valid
      expect(invitation.errors[:base]).to be_present
    end

    it "is invalid with neither theater nor production" do
      invitation = build(:invitation, theater: nil, production: nil)
      expect(invitation).not_to be_valid
      expect(invitation.errors[:base]).to be_present
    end

    it "is valid with only a production" do
      invitation = build(:invitation, :for_production, theater: nil)
      expect(invitation).to be_valid
    end
  end

  describe "#stale?" do
    it "is true once expires_at has passed and status is still pending" do
      invitation = create(:invitation, :stale)
      expect(invitation.stale?).to be true
    end

    it "is false for a pending invitation within its window" do
      invitation = create(:invitation)
      expect(invitation.stale?).to be false
    end

    it "is false once accepted, even if expires_at has passed" do
      invitation = create(:invitation, :stale, :accepted)
      expect(invitation.stale?).to be false
    end

    it "is false once the status has already transitioned to expired (distinct from the enum's own #expired?)" do
      invitation = create(:invitation, :expired_status)
      expect(invitation.stale?).to be false
      expect(invitation.expired?).to be true
    end
  end
end
