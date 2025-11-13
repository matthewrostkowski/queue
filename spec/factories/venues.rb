FactoryBot.define do
  factory :venue do
    name { "Venue #{SecureRandom.hex(4)}" }
    location { "123 Main St" }
    capacity { 200 }
    
    trait :with_pricing_enabled do
      pricing_enabled { true }
      base_price_cents { 100 }
      min_price_cents { 1 }
      max_price_cents { 50000 }
      price_multiplier { 1.0 }
      peak_hours_start { 19 }
      peak_hours_end { 23 }
      peak_hours_multiplier { 1.5 }
    end
    
    trait :with_high_prices do
      pricing_enabled { true }
      base_price_cents { 1000 }
      min_price_cents { 100 }
      max_price_cents { 100000 }
      price_multiplier { 2.0 }
    end
  end
end
