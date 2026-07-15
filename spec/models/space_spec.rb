require 'rails_helper'

RSpec.describe Space, type: :model do
  it "has a valid factory" do
    expect(build(:space)).to be_valid
  end

  let(:space) { build(:space) }
  describe "ActiveRecord associations" do
    it { expect(space).to have_many(:space_agreements).dependent(:destroy) }
    it { expect(space).to have_many(:theaters).through(:space_agreements) }
  end
  it { expect(space).to validate_presence_of(:name)}

  describe "#full_address" do
    it "joins the present address fields" do
      space = build(:space, street_address: '123 Main St', city: 'Springfield', state: 'IL', zip: '62704')
      expect(space.full_address).to eq('123 Main St, Springfield, IL, 62704')
    end

    it "skips blank fields" do
      space = build(:space, street_address: nil, city: 'Springfield', state: nil, zip: '62704')
      expect(space.full_address).to eq('Springfield, 62704')
    end

    it "is blank when no address fields are set" do
      space = build(:space, street_address: nil, city: nil, state: nil, zip: nil)
      expect(space.full_address).to eq('')
    end
  end
end
