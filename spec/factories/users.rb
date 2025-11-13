FactoryBot.define do
  factory :user do
    display_name { Faker::Name.name }
    email { Faker::Internet.email }
    auth_provider { "local" }
    password { "password123" }
    balance_cents { 1000 }

    trait :admin do
      role { :admin }
    end

    trait :low_balance do
      balance_cents { 50 }
    end

    trait :high_balance do
      balance_cents { 10000 }
    end
  end
end
