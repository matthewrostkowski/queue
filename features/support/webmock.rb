Before("@stub_search") do
  stub_request(:get, %r{\Ahttps?://api\.deezer\.com/search})
    .with { |req| URI(req.uri).query&.include?("q=") }
    .to_return(
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: {
        data: [
          {
            id: 3420418861,
            title: "Sofia",
            duration: 188,
            preview: "https://example.com/sofia.mp3",
            artist: { name: "Clairo" },
            album:  { cover: "https://example.com/sofia.jpg" }
          }
        ],
        total: 1
      }.to_json
    )
end
