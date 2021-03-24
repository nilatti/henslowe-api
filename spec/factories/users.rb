FactoryBot.define do
  factory :user do
    bio {Faker::Hipster.paragraph}
    birthdate { Faker::Date.birthday(min_age: 18, max_age: 65) }
    city { Faker::Address.city }
    description { Faker::Movies::HitchhikersGuideToTheGalaxy.quote }
    email { Faker::Internet.email }
    emergency_contact_name { Faker::Name.name }
    emergency_contact_number { Faker::PhoneNumber.cell_phone }
    first_name { Faker::Name.first_name }
    gender { Faker::Gender.type }
    last_name { Faker::Name.last_name }
    middle_name { Faker::Name.middle_name }
    password {'testtesttest'}
    phone_number { Faker::PhoneNumber.cell_phone }
    program_name { Faker::Name.name }
    role { "regular" }
    state { Faker::Address.state_abbr }
    street_address { Faker::Address.street_address }
    timezone { 'EST' }
    website { Faker::Internet.url }
    zip { Faker::Address.zip }
  end
end
