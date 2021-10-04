FactoryBot.define do
  factory :specialization do
    title { Faker::BossaNova.song }
    description { Faker::GreekPhilosophers.quote }
    theater_admin {false}
    production_admin {false}

    trait :actor do
      title { 'Actor' }
    end

    trait :auditioner do
      title { 'Auditioner' }
    end

    trait :admin do
      theater_admin {true}
    end
  end
end
