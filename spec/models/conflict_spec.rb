require 'rails_helper'

describe Conflict do

  it "has a valid factory" do
    expect(create(:conflict)).to be_valid
  end

  let(:conflict) { build(:conflict) }

  describe "ActiveModel validations" do
    it { expect(conflict).to validate_presence_of(:start_time) }
    it { expect(conflict).to validate_presence_of(:end_time) }
  end

  describe "ActiveRecord associations" do
      it { expect(conflict).to belong_to(:user).optional }
      it { expect(conflict).to belong_to(:space).optional }
      it { expect(conflict).to belong_to(:rehearsal).optional }
  end

  describe "instance methods" do
    it "checks for either user or space" do
      conflict_with_none = build(:conflict, :neither)
      conflict_with_none.valid?
      expect(conflict_with_none.errors[:conflict]).to include("Must have either user or space")

      conflict_with_none = build(:conflict, :both)
      conflict_with_none.valid?
      expect(conflict_with_none.errors[:conflict]).to include("You can only have a space OR a user, not both.")

      conflict_with_none = build(:conflict, :space)
      conflict_with_none.valid?
      expect(conflict_with_none.errors[:conflict].length).to eq(0)

      conflict_with_none = build(:conflict)
      conflict_with_none.valid?
      expect(conflict_with_none.errors[:conflict].length).to eq(0)
    end
  end
end
