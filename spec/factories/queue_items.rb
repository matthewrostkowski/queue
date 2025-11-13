FactoryBot.define do
  factory :queue_item do
    association :song
    association :queue_session
    association :user
    base_price_cents { 100 }
    vote_count { 0 }
    vote_score { 0 }
    base_priority { 0 }
    status { "pending" }

    trait :played do
      status { "played" }
    end

    trait :with_votes do
      vote_count { 5 }
      vote_score { 3 }
    end

    trait :high_priority do
      base_priority { 10 }
    end

    trait :recent do
      created_at { 5.minutes.ago }
    end

    trait :old do
      created_at { 2.hours.ago }
    end
  end
end
