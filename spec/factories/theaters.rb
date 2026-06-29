FactoryBot.define do
  factory :theater do
    name { Faker::Name.first_name }
    street_address { Faker::Address.street_address }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    zip { Faker::Address.zip }
    phone_number { Faker::PhoneNumber.cell_phone }
    mission_statement { Faker::Movies::HarryPotter.quote }
    website { Faker::Internet.url }
    calendar_url { Faker::Internet.url }

    trait :fake do
      fake { true }
    end

    trait :has_spaces do
      after(:create) do |theater|
        theater.spaces << create_list(:space, 3)
      end
    end
  end
end
