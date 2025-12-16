require "rails_helper"

RSpec.describe "Main", type: :request do
  let(:user) do
    User.create!(
      display_name: "TestUser",
      auth_provider: "guest",
      email: "guest@example.com",
      password: "password"
    )
  end

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:current_user)
      .and_return(user)

    allow_any_instance_of(ApplicationController)
      .to receive(:authenticate_user!)
      .and_return(true)
  end

  def build_queue_session!(attrs = {})
    if attrs.key?(:venue)
      venue = attrs[:venue]
    else
      host_user = User.create!(display_name: "Host", email: "host@example.com", password: "password", auth_provider: "general_user", role: :host)
      venue = Venue.create!(name: "Test Venue", host_user_id: host_user.id)
    end
    QueueSession.create!(
      venue: venue,
      created_at: attrs[:created_at] || 30.minutes.ago,
      playback_started_at: attrs[:playback_started_at] || 25.minutes.ago,
      is_active: true,
      is_playing: true
    )
  end

  def add_queue_item!(queue_session:, title:, artist:, currently_playing: false, played_at: nil)
    QueueItem.create!(
      queue_session: queue_session,
      title: title,
      artist: artist,
      is_currently_playing: currently_playing,
      played_at: played_at
    )
  end

  describe "GET /mainpage" do
    it "shows the welcome card and buttons" do
      get mainpage_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Welcome to Queue")
      expect(response.body).to include("Scan QR")
      expect(response.body).to include("Search Songs")
    end

    it "shows empty state when there are no sessions" do
      get mainpage_path
      expect(response.body).to include("No active sessions")
      expect(response.body).to include("Be the first to start a live queue!")
    end

    it "lists a live session with now playing track" do
      s = build_queue_session!
      add_queue_item!(queue_session: s, title: "Old", artist: "Someone", played_at: 10.minutes.ago)
      add_queue_item!(queue_session: s, title: "Current Jam", artist: "DJ Test", currently_playing: true)

      get mainpage_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Live Queues")

      code = s.reload.access_code
      expect(code).to be_present
      expect(response.body).to include(code)

      expect(response.body).to include("Current Jam — DJ Test")
    end
  end
end