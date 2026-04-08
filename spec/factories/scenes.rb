FactoryBot.define do
  factory :scene do
    number { Faker::Number.within(range: 1..10) }
    summary { Faker:: Hipster.sentence}
    act

    trait :with_french_scenes do
      after(:create) do |scene|
        fs_number = 'a'
        create_list(:french_scene, 3, scene: scene) do |french_scene|
          french_scene.number = fs_number
          fs_number.next!
          french_scene.save
        end
      end
    end
  end
end
