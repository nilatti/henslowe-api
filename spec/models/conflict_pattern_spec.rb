require 'rails_helper'

describe ConflictPattern do

  it "has a valid factory" do
    expect(create(:conflict_pattern)).to be_valid
  end

  let(:conflict_pattern) { build(:conflict_pattern) }

  describe "ActiveModel validations" do
    it { expect(conflict_pattern).to validate_presence_of(:start_date) }
    it { expect(conflict_pattern).to validate_presence_of(:end_date) }
    it { expect(conflict_pattern).to validate_presence_of(:start_time) }
    it { expect(conflict_pattern).to validate_presence_of(:end_time) }
  end

  describe "ActiveRecord associations" do
      it { expect(conflict_pattern).to belong_to(:user).optional }
      it { expect(conflict_pattern).to belong_to(:space).optional }
      it { expect(conflict_pattern).to have_many(:conflicts)}
      it 'deletes associated conflicts if the conflict pattern is deleted' do
        conflict_pattern_with_assoc = create(:conflict_pattern)
      before_conflicts_size = Conflict.where(conflict_pattern: conflict_pattern_with_assoc).size
      conflict_pattern_with_assoc.destroy
      after_conflicts_size = Conflict.where(conflict_pattern: conflict_pattern_with_assoc).size
      expect(before_conflicts_size).to eq(3)
      expect(after_conflicts_size).to eq(0)
    end
  end

  describe "instance methods" do
    it "checks for either user or space" do
      conflict_pattern_with_none = build(:conflict_pattern, :neither)
      conflict_pattern_with_none.valid?
      expect(conflict_pattern_with_none.errors[:conflict_pattern]).to include("Must have either user or space")

      conflict_pattern_with_none = build(:conflict_pattern, :both)
      conflict_pattern_with_none.valid?
      expect(conflict_pattern_with_none.errors[:conflict_pattern]).to include("You can only have a space OR a user, not both.")

      conflict_pattern_with_none = build(:conflict_pattern, :space)
      conflict_pattern_with_none.valid?
      expect(conflict_pattern_with_none.errors[:conflict_pattern].length).to eq(0)

      conflict_pattern_with_none = build(:conflict_pattern)
      conflict_pattern_with_none.valid?
      expect(conflict_pattern_with_none.errors[:conflict_pattern].length).to eq(0)
    end
  end
end
