require "rails_helper"

RSpec.describe "QueueItemsController", type: :request do
  let!(:user)  { User.create!(display_name: "SpecUser", auth_provider: "guest") }
  let!(:venue) { Venue.create!(name: "SpecVenue") }
  let!(:qs)    { QueueSession.create!(venue: venue, is_active: true) }
  let!(:song1) { Song.create!(title: "Alpha", artist: "A") }
  let!(:song2) { Song.create!(title: "Beta",  artist: "B") }

  before { login_as(user) }

  describe "GET /queue_items?queue_session_id=..." do
    it "returns pending items ordered by vote_count, base_priority, created_at" do
      qi1 = QueueItem.create!(song: song1, queue_session: qs, user: user, base_price: 1.0, vote_count: 1, base_priority: 0, status: "pending")
      sleep 0.01
      qi2 = QueueItem.create!(song: song2, queue_session: qs, user: user, base_price: 1.0, vote_count: 2, base_priority: 0, status: "pending")

      get "/queue_items", params: { queue_session_id: qs.id }, as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.map { |h| h["id"] }).to eq([qi2.id, qi1.id]) # 2 票在前
      expect(body.first).to include("price_for_display")
      expect(body.first["song"]).to include("title", "artist")
    end

    it "returns 422 when queue_session_id is missing" do
      get "/queue_items", as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /queue_items" do
    it "creates a queue item via JSON params" do
      expect {
        post "/queue_items",
             params: { queue_item: { song_id: song1.id, queue_session_id: qs.id, base_price: 3.99 } },
             as: :json
      }.to change(QueueItem, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body).to include("id", "price_for_display")
    end

    it "creates a queue item when queue_item is JSON string (form hidden field case)" do
      payload = { song_id: song2.id, queue_session_id: qs.id, base_price: 2.5 }.to_json
      expect {
        post "/queue_items", params: { queue_item: payload }, as: :json
      }.to change(QueueItem, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe "PATCH /queue_items/:id/vote" do
    it "increments vote_count by delta" do
      qi = QueueItem.create!(song: song1, queue_session: qs, user: user, base_price: 1.0, vote_count: 0)
      patch "/queue_items/#{qi.id}/vote", params: { delta: 1 }, as: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include("votes" => 1)
      expect(qi.reload.vote_count).to eq(1)
    end
  end
end
