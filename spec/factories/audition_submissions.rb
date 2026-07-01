FactoryBot.define do
  factory :audition_submission do
    job
    video_url { nil }
    notes { nil }
  end
end
