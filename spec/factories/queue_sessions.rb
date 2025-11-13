FactoryBot.define do
  factory :queue_session do
    association :venue
    is_active { true }

    trait :inactive do
      is_active { false }
    end
  end
end
