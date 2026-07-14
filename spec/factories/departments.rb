FactoryBot.define do
  factory :department do
    name { Faker::Job.field }
    description { Faker::GreekPhilosophers.quote }
  end
end
