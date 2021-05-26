FactoryBot.define do
  factory :rehearsal do
    production
    start_time { Faker::Time.between_dates(from: production.start_date, to: production.end_date, period: :evening )}
    end_time { start_time + 1.hour  }
    notes { Faker::Quotes::Shakespeare.king_richard_iii_quote}
    title { Faker::GreekPhilosophers.quote}
    space

    trait :no_space do
      space {nil}
    end
  end
end
