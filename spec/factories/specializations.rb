FactoryBot.define do
  factory :specialization do
    title { Faker::Music::Prince.song }
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

    trait :theater_admin do
      theater_admin {true}
    end

    trait :artistic_director do
      title { 'Artistic Director' }
      theater_admin {true}
    end

    trait :director do
      title { 'Director' }
      production_admin {true}
    end
  end
end
