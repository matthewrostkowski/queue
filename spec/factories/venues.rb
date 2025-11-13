FactoryBot.define do
  factory :venue do
    name { "Test Venue" }
    location { "123 Main St, Test City, TC" }
    capacity { 200 }
    pricing_enabled { true }
    base_price_cents { 100 }
    price_multiplier { 1.0 }
    min_price_cents { 50 }
    max_price_cents { 1000 }
    peak_hours_start { 18 } # 6 PM
    peak_hours_end { 22 }   # 10 PM
    peak_hours_multiplier { 1.5 }

    trait :no_pricing do
      pricing_enabled { false }
    end

    trait :expensive do
      base_price_cents { 200 }
      price_multiplier { 1.5 }
    end

    trait :peak_hours do
      peak_hours_start { 20 }
      peak_hours_end { 2 }
      peak_hours_multiplier { 2.0 }
    end

    trait :high_prices do
      base_price_cents { 1000 }
      min_price_cents { 100 }
      max_price_cents { 100000 }
      price_multiplier { 2.0 }
    end
  end
end
