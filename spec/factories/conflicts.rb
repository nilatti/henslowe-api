FactoryBot.define do
  factory :conflict do
    start_time { Faker::Time.forward(days: 1, period: :afternoon) }
    end_time { Faker::Time.forward(days: 1, period: :evening)  }
    category { ['personal', 'rehearsal', 'work']}
    user
    space {nil}
    conflict_pattern { nil }

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

  end
end
