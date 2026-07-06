require 'rails_helper'

RSpec.describe Production, type: :model do
  it "has a valid factory" do
    expect(build(:production)).to be_valid
  end

  describe "end_date_after_start_date" do
    it "is valid with no dates at all" do
      production = build(:production, start_date: nil, end_date: nil)
      expect(production).to be_valid
    end

    it "is valid with only a start date" do
      production = build(:production, start_date: Date.today, end_date: nil)
      expect(production).to be_valid
    end

    it "is valid with only an end date" do
      production = build(:production, start_date: nil, end_date: Date.today)
      expect(production).to be_valid
    end

    it "is valid when the end date is after the start date" do
      production = build(:production, start_date: Date.today, end_date: 1.week.from_now)
      expect(production).to be_valid
    end

    it "is invalid when the end date is before the start date" do
      production = build(:production, start_date: Date.today, end_date: 1.week.ago)
      production.valid?
      expect(production.errors[:end_date]).to include("can't be before start date")
    end
  end
end
