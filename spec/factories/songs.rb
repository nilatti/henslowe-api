FactoryBot.define do
  factory :song do
    title { Faker::Music.album }
    french_scene
  end
end
