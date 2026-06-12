FactoryBot.define do
  factory :phase do
    sequence(:name) { |n| "Phase #{n}" }
    position { nil }
  end
end
