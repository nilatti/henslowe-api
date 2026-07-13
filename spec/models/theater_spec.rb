require 'rails_helper'

RSpec.describe Theater, type: :model do
  it "has a valid factory" do
    expect(build(:theater)).to be_valid
  end

  let(:theater) { build(:theater) }
  describe "ActiveRecord associations" do
    it { expect(theater).to have_many(:productions) }
    it { expect(theater).to have_many(:space_agreements) }
    it { expect(theater).to have_many(:spaces).through(:space_agreements) }
  end
  it { expect(theater).to validate_presence_of(:name)}
  it { expect(theater).to validate_numericality_of(:reserved_seats).only_integer.is_greater_than_or_equal_to(1) }
  it "orders by name" do
    theater1 = create(:theater, name: "Drury Lane")
    theater3 = create(:theater, name: "Roy Rogers")
    theater2 = create(:theater, name: "Guthrie")
    expect(Theater.all.last).to eq(theater3)
  end

  describe "#has_active_subscription?" do
    it "is true when subscription_status is active" do
      expect(build(:theater, subscription_status: 'active').has_active_subscription?).to be true
    end

    it "is false when inactive or unset" do
      expect(build(:theater, subscription_status: 'canceled').has_active_subscription?).to be false
      expect(build(:theater, subscription_status: nil).has_active_subscription?).to be false
    end
  end

  describe "#sponsored_jobs" do
    let!(:sponsoring_theater) { create(:theater, subscription_status: 'active') }
    let!(:production) { create(:production, theater: sponsoring_theater) }
    let!(:director_spec) { create(:specialization, :director) }
    let!(:unpaid_user) { create(:user) }

    it "includes an active theater-sponsored job directly on the theater" do
      job = create(:job, user: unpaid_user, theater: sponsoring_theater, production: nil,
                          specialization: director_spec, theater_sponsored: true,
                          start_date: 1.day.ago, end_date: nil)
      expect(sponsoring_theater.sponsored_jobs).to include(job)
    end

    it "includes an active theater-sponsored job on one of the theater's productions" do
      job = create(:job, user: unpaid_user, theater: nil, production: production,
                          specialization: director_spec, theater_sponsored: true,
                          start_date: 1.day.ago, end_date: nil)
      expect(sponsoring_theater.sponsored_jobs).to include(job)
    end

    it "excludes non-sponsored jobs" do
      job = create(:job, user: create(:user, :paid), theater: sponsoring_theater, production: nil,
                          specialization: director_spec, theater_sponsored: false,
                          start_date: 1.day.ago, end_date: nil)
      expect(sponsoring_theater.sponsored_jobs).not_to include(job)
    end

    it "excludes sponsored jobs that have already ended" do
      job = create(:job, user: unpaid_user, theater: sponsoring_theater, production: nil,
                          specialization: director_spec, theater_sponsored: true,
                          start_date: 2.days.ago, end_date: 1.day.ago)
      expect(sponsoring_theater.sponsored_jobs).not_to include(job)
    end
  end

  describe "#sync_seat_quantity!" do
    let(:theater) { create(:theater, stripe_customer_id: 'cus_123') }
    let(:subscription_item) { double(id: 'si_123', quantity: 99) }
    let(:subscription) { double(items: double(data: [subscription_item])) }

    before do
      allow(Stripe::Subscription).to receive(:list).with(customer: 'cus_123').and_return(double(data: [subscription]))
    end

    it "does nothing when stripe_customer_id is blank" do
      blank_theater = build(:theater, stripe_customer_id: nil)
      expect(Stripe::Subscription).not_to receive(:list)
      blank_theater.sync_seat_quantity!
    end

    it "sets quantity to a minimum of 1 when there are no sponsored jobs" do
      expect(Stripe::SubscriptionItem).to receive(:update).with('si_123', quantity: 1, proration_behavior: 'always_invoice')
      theater.sync_seat_quantity!
    end

    it "sets quantity to the current sponsored count when higher than 1" do
      allow(theater).to receive(:sponsored_jobs).and_return(double(count: 3))
      expect(Stripe::SubscriptionItem).to receive(:update).with('si_123', quantity: 3, proration_behavior: 'always_invoice')
      theater.sync_seat_quantity!
    end

    it "keeps quantity at reserved_seats when it's higher than the current sponsored count" do
      theater.update!(reserved_seats: 5)
      allow(theater).to receive(:sponsored_jobs).and_return(double(count: 2))
      expect(Stripe::SubscriptionItem).to receive(:update).with('si_123', quantity: 5, proration_behavior: 'always_invoice')
      theater.sync_seat_quantity!
    end

    it "uses the sponsored count when it exceeds reserved_seats" do
      theater.update!(reserved_seats: 2)
      allow(theater).to receive(:sponsored_jobs).and_return(double(count: 5))
      expect(Stripe::SubscriptionItem).to receive(:update).with('si_123', quantity: 5, proration_behavior: 'always_invoice')
      theater.sync_seat_quantity!
    end

    it "skips the update when quantity already matches" do
      allow(subscription_item).to receive(:quantity).and_return(1)
      expect(Stripe::SubscriptionItem).not_to receive(:update)
      theater.sync_seat_quantity!
    end

    it "logs and does not raise on a Stripe error" do
      allow(Stripe::SubscriptionItem).to receive(:update).and_raise(Stripe::StripeError.new("boom"))
      expect { theater.sync_seat_quantity! }.not_to raise_error
    end
  end
end
