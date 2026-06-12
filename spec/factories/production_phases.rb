FactoryBot.define do
  factory :production_phase do
    production
    phase
    start_date { Faker::Date.between(from: Date.today, to: 6.months.from_now) }
    end_date   { Faker::Date.between(from: 6.months.from_now, to: 1.year.from_now) }
  end
end
