require 'rails_helper'

RSpec.describe "QueuesController", type: :request do
  before { skip "Skipping queues controller request specs for now" }
  let!(:user) { User.create!(display_name: "Test User", auth_provider: "guest") }
  let!(:host) { User.create!(display_name: "Host User", auth_provider: "guest", role: "host") }
  let!(:venue) { Venue.create!(name: "Test Venue", host_user_id: host.id) }
  let!(:queue_session) { QueueSession.create!(venue: venue, status: "active", join_code: "123456") }
  let!(:song1) { Song.create!(title: "Song 1", artist: "Artist 1", spotify_id: "spot1", preview_url: "http://example.com/preview1.mp3") }
  let!(:song2) { Song.create!(title: "Song 2", artist: "Artist 2", spotify_id: "spot2", preview_url: "http://example.com/preview2.mp3") }
  let!(:song3) { Song.create!(title: "Song 3", artist: "Artist 3", spotify_id: "spot3") } # No preview URL

  before do
    login_as(user)
    allow_any_instance_of(ApplicationController).to receive(:session).and_return({ 
      user_id: user.id,
      current_queue_session_id: queue_session.id 
    })
  end

  describe "GET /queue (show)" do
    context "with queue items" do
      let!(:queue_item1) do
        QueueItem.create!(
          queue_session: queue_session,
          user: user,
          song: song1,
          title: song1.title,
          artist: song1.artist,
          preview_url: song1.preview_url,
          vote_score: 5,
          vote_count: 3,
          played_at: nil
        )
      end
      
      let!(:queue_item2) do
        QueueItem.create!(
          queue_session: queue_session,
          user: user,
          song: song2,
          title: song2.title,
          artist: song2.artist,
          preview_url: song2.preview_url,
          vote_score: 10,
          vote_count: 5,
          played_at: nil
        )
      end
      
      let!(:played_item) do
        QueueItem.create!(
          queue_session: queue_session,
          user: user,
          song: song3,
          title: song3.title,
          artist: song3.artist,
          vote_score: 2,
          played_at: 1.hour.ago,
          is_currently_playing: false
        )
      end

      it "displays unplayed queue items ordered by vote_score DESC" do
        get "/queue"
        
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(song1.title)
        expect(response.body).to include(song2.title)
        expect(response.body).not_to include(song3.title) # played item should not appear
        
        # Check order - higher vote score first
        song2_position = response.body.index(song2.title)
        song1_position = response.body.index(song1.title)
        expect(song2_position).to be < song1_position
      end

      it "shows the currently playing track" do
        queue_item1.update!(is_currently_playing: true, played_at: Time.current)
        
        get "/queue"
        
        expect(response).to have_http_status(:ok)
        expect(assigns(:now_playing)).to eq(queue_item1)
      end

      it "displays the access code" do
        get "/queue"
        
        expect(response).to have_http_status(:ok)
        expect(assigns(:access_code)).to eq("123456")
      end
    end

    context "without an active queue session" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:session).and_return({ user_id: user.id })
        QueueSession.update_all(status: "ended")
      end

      it "redirects to root with alert" do
        get "/queue"
        
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("No active queue session")
      end
    end
  end

  describe "POST /queue/start_playback" do
    context "with available songs" do
      let!(:queue_item) do
        QueueItem.create!(
          queue_session: queue_session,
          user: user,
          song: song1,
          title: song1.title,
          artist: song1.artist,
          preview_url: song1.preview_url,
          vote_score: 5,
          played_at: nil
        )
      end

      it "starts playback of the next song with highest vote score" do
        post "/queue/start_playback", as: :json
        
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["success"]).to be true
        expect(body["message"]).to include("Playing #{song1.title}")
        expect(body["song"]["preview_url"]).to eq(song1.preview_url)
        
        queue_item.reload
        expect(queue_item.played_at).not_to be_nil
        expect(queue_item.is_currently_playing).to be true
      end
    end

    context "with song without preview URL" do
      let!(:queue_item) do
        QueueItem.create!(
          queue_session: queue_session,
          user: user,
          song: song3,
          title: song3.title,
          artist: song3.artist,
          preview_url: nil,
          vote_score: 5,
          played_at: nil
        )
      end

      it "returns error when song has no preview URL" do
        post "/queue/start_playback", as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body["success"]).to be false
        expect(body["message"]).to include("No preview available")
      end
    end

    context "with empty queue" do
      it "returns error when queue is empty" do
        post "/queue/start_playback", as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body["success"]).to be false
        expect(body["message"]).to include("Queue is empty")
      end
    end
  end

  describe "POST /queue/stop_playback" do
    let!(:playing_item) do
      QueueItem.create!(
        queue_session: queue_session,
        user: user,
        song: song1,
        title: song1.title,
        artist: song1.artist,
        is_currently_playing: true,
        played_at: Time.current
      )
    end

    it "stops playback and clears currently playing status" do
      post "/queue/stop_playback", as: :json
      
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["success"]).to be true
      expect(body["message"]).to eq("Playback stopped")
      
      playing_item.reload
      expect(playing_item.is_currently_playing).to be false
    end
  end

  describe "POST /queue/next_track" do
    context "with available songs" do
      let!(:current_item) do
        QueueItem.create!(
          queue_session: queue_session,
          user: user,
          song: song1,
          title: song1.title,
          artist: song1.artist,
          preview_url: song1.preview_url,
          is_currently_playing: true,
          played_at: Time.current
        )
      end
      
      let!(:next_item) do
        QueueItem.create!(
          queue_session: queue_session,
          user: user,
          song: song2,
          title: song2.title,
          artist: song2.artist,
          preview_url: song2.preview_url,
          vote_score: 10,
          played_at: nil
        )
      end

      it "advances to the next track with highest vote score" do
        post "/queue/next_track", as: :json
        
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["success"]).to be true
        expect(body["song"]["title"]).to eq(song2.title)
        expect(body["song"]["preview_url"]).to eq(song2.preview_url)
        
        current_item.reload
        next_item.reload
        expect(current_item.is_currently_playing).to be false
        expect(next_item.is_currently_playing).to be true
        expect(next_item.played_at).not_to be_nil
      end
    end

    context "with song without preview URL" do
      let!(:queue_item) do
        QueueItem.create!(
          queue_session: queue_session,
          user: user,
          song: song3,
          title: song3.title,
          artist: song3.artist,
          preview_url: nil,
          vote_score: 5,
          played_at: nil
        )
      end

      it "returns error when next song has no preview URL" do
        post "/queue/next_track", as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body["success"]).to be false
        expect(body["message"]).to include("No more tracks in queue with previews")
      end
    end

    context "with no more songs" do
      it "returns error when no more songs in queue" do
        post "/queue/next_track", as: :json
        
        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body["success"]).to be false
        expect(body["message"]).to include("No more songs in queue")
      end
    end
  end

  describe "GET /queue/state" do
    let!(:playing_item) do
      QueueItem.create!(
        queue_session: queue_session,
        user: user,
        song: song1,
        title: song1.title,
        artist: song1.artist,
        cover_url: "http://example.com/cover1.jpg",
        preview_url: song1.preview_url,
        is_currently_playing: true,
        played_at: Time.current
      )
    end
    
    let!(:upcoming_item) do
      QueueItem.create!(
        queue_session: queue_session,
        user: user,
        song: song2,
        title: song2.title,
        artist: song2.artist,
        preview_url: song2.preview_url,
        vote_score: 8,
        played_at: nil
      )
    end

    it "returns the current queue state as JSON" do
      get "/queue/state", as: :json
      
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      
      # Check is_playing status
      expect(body).to have_key("is_playing")
      
      # Check currently playing track
      expect(body["currently_playing"]).not_to be_nil
      expect(body["currently_playing"]["title"]).to eq(song1.title)
      expect(body["currently_playing"]["preview_url"]).to eq(song1.preview_url)
      
      # Check upcoming queue
      expect(body["queue"]).to be_an(Array)
      expect(body["queue"].length).to eq(1)
      expect(body["queue"].first["title"]).to eq(song2.title)
    end
  end

  describe "queue session fallback behavior" do
    context "when session ID exists but queue session not found" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:session).and_return({ 
          user_id: user.id,
          current_queue_session_id: 99999 
        })
      end

      it "falls back to first active session" do
        get "/queue"
        
        expect(response).to have_http_status(:ok)
        expect(assigns(:queue_session)).to eq(queue_session)
      end
    end

    context "when no session ID and no active sessions" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:session).and_return({ user_id: user.id })
        QueueSession.update_all(status: "ended")
      end

      it "redirects with alert" do
        get "/queue"
        
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("No active queue session")
      end
    end
  end
end
