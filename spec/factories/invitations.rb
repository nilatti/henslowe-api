FactoryBot.define do
  factory :invitation do
    email { Faker::Internet.email }
    payment_responsibility { :self_pays }
    theater { create(:theater) }
    specialization { create(:specialization) }
    invited_by { create(:user) }

    trait :for_production do
      theater { nil }
      production { create(:production) }
    end

    trait :theater_sponsored do
      payment_responsibility { :theater_pays }
    end

    trait :stale do
      expires_at { 1.day.ago }
    end

    trait :expired_status do
      status { :expired }
      expires_at { 1.day.ago }
    end

    trait :accepted do
      status { :accepted }
      accepted_at { Time.current }
      association :accepted_user, factory: :user
    end

    trait :revoked do
      status { :revoked }
    end
  end
end
