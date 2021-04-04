FactoryBot.define do
  factory :conflict_pattern do
    start_date { Faker::Date.forward(days: 1) }
    end_date { Faker::Date.forward(days: 30) }
    start_time {"05:00"}
    end_time { "09:00" }
    category { ['personal', 'rehearsal', 'work']}
    user
    space {nil}

    trait :space do
      space
      user {nil}
    end
    trait :both do
      space
      user
    end
    trait :neither do
      space {nil }
      user {nil }
    end

    after(:create) do |conflict_pattern|
      create_list(:conflict, 3, user: conflict_pattern.user, conflict_pattern: conflict_pattern)
    end

  end
end
