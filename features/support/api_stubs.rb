# features/support/api_stubs.rb
require "webmock/cucumber"
require "json"

Before("@stub_search") do
  # Stub Deezer search API regardless of query so tests are stable
  stub_request(:get, /api\.deezer\.com\/search.*/i)
    .to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        data: [
          {
            "id" => 3420418861,
            "title" => "Sofia",
            "preview" => "https://example.test/preview.mp3",
            "artist" => { "name" => "Clairo" },
            "album" => { "cover_medium" => "https://example.test/cover.jpg" }
          },
          {
            "id" => 1234567890,
            "title" => "Bags",
            "preview" => "https://example.test/preview2.mp3",
            "artist" => { "name" => "Clairo" },
            "album" => { "cover_medium" => "https://example.test/cover2.jpg" }
          }
        ],
        "total" => 2
      }.to_json
    )
end
