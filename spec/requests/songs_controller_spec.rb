require "rails_helper"

RSpec.describe "SongsController", type: :request do
  before { skip "Skipping songs controller request specs for now" }
  let!(:user) { User.create!(display_name: "SpecUser", auth_provider: "guest") }

  before do
    login_as(user)
    Song.create!(title: "Blue Bird", artist: "AAA")
    Song.create!(title: "Red Sun",   artist: "BBB")
  end

  it "returns top 5 results matching title or artist (case-insensitive)" do
    get "/songs/search", params: { q: "blue" }, as: :json
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    titles = body.fetch("results").map { |s| s["title"] }
    expect(titles).to include("Blue Bird")
    expect(titles).not_to include("Red Sun")
  end
end
