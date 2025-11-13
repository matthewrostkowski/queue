FactoryBot.define do
  factory :song do
    title { Faker::Music::RockBand.song }
    artist { Faker::Music.band }
    cover_url { "https://example.com/cover.jpg" }
    duration_ms { 180000 } # 3 minutes
    preview_url { "https://example.com/preview.mp3" }
    spotify_id { SecureRandom.hex(10) }
  end
end
