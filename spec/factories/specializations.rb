FactoryBot.define do
  factory :specialization do
    title { Faker::Music::Prince.song }
    description { Faker::GreekPhilosophers.quote }
    theater_admin { false }
    production_admin { false }
    context { :both }

    trait :actor do
      title { 'Actor' }
      context { :production }
    end

    trait :auditioner do
      title { 'Auditioner' }
      context { :production }
    end

    trait :admin do
      theater_admin { true }
    end

    trait :theater_admin do
      theater_admin { true }
      context { :theater }
    end

    trait :artistic_director do
      title { 'Artistic Director' }
      theater_admin { true }
      context { :theater }
    end

    trait :director do
      title { 'Director' }
      production_admin { true }
      context { :production }
    end

    trait :theater_context do
      context { :theater }
    end

    trait :production_context do
      context { :production }
    end
  end
end
