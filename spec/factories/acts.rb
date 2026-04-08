FactoryBot.define do
  factory :act do
    number { Faker::Number.within(range: 1..10) }
    summary { Faker:: Hipster.sentence}
    play

    trait :with_scenes do
      after(:create) do |act|
        create_list(:scene, 3, :with_french_scenes, act: act) do |scene, i|
          scene.number = (i + 1)
          scene.save
        end
      end
    end
  end
end
