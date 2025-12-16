require 'rails_helper'

RSpec.describe "Host::VenuesController", type: :request do
  let!(:host_user) { User.create!(display_name: "Host", email: "host@example.com", password: "password", auth_provider: "general_user", role: :host) }
  let!(:other_host) { User.create!(display_name: "Other Host", email: "other@example.com", password: "password", auth_provider: "general_user", role: :host) }
  let!(:regular_user) { User.create!(display_name: "Regular", email: "regular@example.com", password: "password", auth_provider: "general_user", role: :user) }
  let!(:venue1) { Venue.create!(name: "Venue 1", location: "123 Main St", capacity: 100, host_user_id: host_user.id) }
  let!(:venue2) { Venue.create!(name: "Venue 2", location: "456 Oak Ave", capacity: 200, host_user_id: host_user.id) }
  let!(:other_venue) { Venue.create!(name: "Other Venue", location: "789 Pine St", capacity: 150, host_user_id: other_host.id) }

  before do
    login_as(host_user)
  end

  describe "GET /host/venues" do
    it "displays only venues owned by the current host" do
      get host_venues_path
      
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(venue1.name)
      expect(response.body).to include(venue2.name)
      expect(response.body).not_to include(other_venue.name)
    end
  end

  describe "GET /host/venues/new" do
    it "displays new venue form" do
      get new_host_venue_path
      
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Venue")
    end

    it "requires host role" do
      login_as(regular_user)
      get new_host_venue_path
      expect(response).to redirect_to(mainpage_path)
    end
  end

  describe "POST /host/venues" do
    context "with valid params" do
      it "creates a new venue for the host" do
        expect {
          post host_venues_path, params: {
            venue: {
              name: "New Venue",
              location: "999 Test St",
              capacity: 300
            }
          }
        }.to change(Venue, :count).by(1)
        
        new_venue = Venue.last
        expect(new_venue.host_user_id).to eq(host_user.id)
        expect(new_venue.name).to eq("New Venue")
        
        expect(response).to redirect_to(host_venue_path(new_venue))
        expect(flash[:notice]).to eq("Venue created successfully!")
      end
    end

    context "with invalid params" do
      it "renders new template with errors" do
        expect {
          post host_venues_path, params: {
            venue: { name: "" } # Invalid
          }
        }.not_to change(Venue, :count)
        
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /host/venues/:id" do
    context "for owned venue" do
      let!(:active_session) { QueueSession.create!(venue: venue1, status: "active", join_code: "123456") }
      let!(:ended_session) { QueueSession.create!(venue: venue1, status: "ended", join_code: "654321") }

      it "displays venue details and sessions" do
        get host_venue_path(venue1)
        
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(venue1.name)
        expect(response.body).to include(venue1.location)
        expect(assigns(:sessions)).to include(active_session, ended_session)
        expect(assigns(:active_session)).to eq(active_session)
      end
    end

    context "for venue owned by another host" do
      it "redirects with not authorized message" do
        get host_venue_path(other_venue)
        
        expect(response).to redirect_to(mainpage_path)
        expect(flash[:alert]).to include("not authorized")
      end
    end
  end

  describe "GET /host/venues/:id/edit" do
    context "for owned venue" do
      it "displays edit form" do
        get edit_host_venue_path(venue1)
        
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit")
        expect(response.body).to include(venue1.name)
      end
    end

    context "for venue owned by another host" do
      it "redirects with not authorized message" do
        get edit_host_venue_path(other_venue)
        
        expect(response).to redirect_to(mainpage_path)
        expect(flash[:alert]).to include("not authorized")
      end
    end
  end

  describe "PATCH /host/venues/:id" do
    context "for owned venue with valid params" do
      it "updates the venue and redirects" do
        patch host_venue_path(venue1), params: {
          venue: {
            name: "Updated Name",
            location: "New Location",
            capacity: 500
          }
        }
        
        expect(response).to redirect_to(host_venue_path(venue1))
        expect(flash[:notice]).to eq("Venue updated successfully!")
        
        venue1.reload
        expect(venue1.name).to eq("Updated Name")
        expect(venue1.location).to eq("New Location")
        expect(venue1.capacity).to eq(500)
      end
    end

    context "for owned venue with invalid params" do
      it "renders edit template with errors" do
        patch host_venue_path(venue1), params: {
          venue: { name: "" } # Invalid
        }
        
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "for venue owned by another host" do
      it "redirects with not authorized message" do
        patch host_venue_path(other_venue), params: {
          venue: { name: "Hacked Name" }
        }
        
        expect(response).to redirect_to(mainpage_path)
        expect(flash[:alert]).to include("not authorized")
        
        other_venue.reload
        expect(other_venue.name).not_to eq("Hacked Name")
      end
    end
  end

  describe "DELETE /host/venues/:id" do
    context "for owned venue" do
      it "destroys the venue and redirects" do
        expect {
          delete host_venue_path(venue1)
        }.to change(Venue, :count).by(-1)
        
        expect(response).to redirect_to(host_venues_path)
        expect(flash[:notice]).to eq("Venue deleted successfully")
      end
    end

    context "for venue owned by another host" do
      it "redirects with not authorized message" do
        expect {
          delete host_venue_path(other_venue)
        }.not_to change(Venue, :count)
        
        expect(response).to redirect_to(mainpage_path)
        expect(flash[:alert]).to include("not authorized")
      end
    end
  end

  describe "GET /host/venues/:id/dashboard" do
    let!(:active_session) { QueueSession.create!(venue: venue1, status: "active", join_code: "123456") }
    let!(:song) { Song.create!(title: "Test Song", artist: "Test Artist") }
    let!(:queue_item) { QueueItem.create!(queue_session: active_session, song: song, title: song.title, artist: song.artist, user: host_user, vote_count: 5) }

    it "displays dashboard with active session and queue items" do
      get dashboard_host_venue_path(venue1)
      
      expect(response).to have_http_status(:ok)
      expect(assigns(:active_session)).to eq(active_session)
      expect(assigns(:queue_items)).to include(queue_item)
    end
  end

  describe "POST /host/venues/:id/create_session" do
    context "when no active session exists" do
      it "creates a new session and redirects with notice" do
        expect {
          post create_session_host_venue_path(venue1)
        }.to change(QueueSession, :count).by(1)
        
        expect(response).to redirect_to(host_venue_path(venue1))
        expect(flash[:notice]).to eq("Session started successfully")
        
        new_session = QueueSession.last
        expect(new_session.venue).to eq(venue1)
        expect(new_session.status).to eq("active")
      end
    end

    context "when active session already exists" do
      let!(:existing_session) { QueueSession.create!(venue: venue1, status: "active", join_code: "123456") }

      it "redirects with alert" do
        expect {
          post create_session_host_venue_path(venue1)
        }.not_to change(QueueSession, :count)
        
        expect(response).to redirect_to(host_venue_path(venue1))
        expect(flash[:alert]).to include("Failed to start session")
      end
    end
  end

  describe "POST /host/venues/:id/start_session" do
    it "creates a new session" do
      expect {
        post start_session_host_venue_path(venue1)
      }.to change(QueueSession, :count).by(1)
      
      expect(response).to redirect_to(host_venue_path(venue1))
      expect(flash[:notice]).to eq("Session started!")
    end
  end

  describe "POST /host/venues/:id/pause_session" do
    let!(:active_session) { QueueSession.create!(venue: venue1, status: "active", join_code: "123456") }

    it "pauses the active session" do
      post pause_session_host_venue_path(venue1)
      
      expect(response).to redirect_to(host_venue_path(venue1))
      expect(flash[:notice]).to eq("Session paused")
      
      active_session.reload
      expect(active_session.status).to eq("paused")
    end
  end

  describe "POST /host/venues/:id/resume_session" do
    let!(:paused_session) { QueueSession.create!(venue: venue1, status: "paused", join_code: "123456") }

    it "resumes the paused session" do
      post resume_session_host_venue_path(venue1)
      
      expect(response).to redirect_to(host_venue_path(venue1))
      expect(flash[:notice]).to eq("Session resumed")
      
      paused_session.reload
      expect(paused_session.status).to eq("active")
    end
  end

  describe "POST /host/venues/:id/end_session" do
    let!(:active_session) { QueueSession.create!(venue: venue1, status: "active", join_code: "123456") }

    it "ends the active session" do
      post end_session_host_venue_path(venue1)
      
      expect(response).to redirect_to(host_venue_path(venue1))
      expect(flash[:notice]).to eq("Session ended")
      
      active_session.reload
      expect(active_session.status).to eq("ended")
    end
  end

  describe "POST /host/venues/:id/regenerate_code" do
    let!(:active_session) { QueueSession.create!(venue: venue1, status: "active", join_code: "123456") }

    it "regenerates the join code for active session" do
      old_code = active_session.join_code
      
      post regenerate_code_host_venue_path(venue1)
      
      expect(response).to redirect_to(host_venue_path(venue1))
      expect(flash[:notice]).to eq("Code regenerated")
      
      active_session.reload
      expect(active_session.join_code).not_to eq(old_code)
      expect(active_session.join_code).to match(/^\d{6}$/)
    end

    context "when no active session" do
      it "redirects with alert" do
        post regenerate_code_host_venue_path(venue1)
        
        expect(response).to redirect_to(host_venue_path(venue1))
        expect(flash[:alert]).to eq("No active session")
      end
    end
  end

  describe "PATCH /host/venues/:id/regenerate_venue_code" do
    it "regenerates the venue code" do
      old_code = venue1.venue_code
      
      patch regenerate_venue_code_host_venue_path(venue1)
      
      expect(response).to redirect_to(host_venue_path(venue1))
      expect(flash[:notice]).to eq("Venue code regenerated successfully")
      
      venue1.reload
      expect(venue1.venue_code).not_to eq(old_code) if venue1.respond_to?(:venue_code)
    end
  end

  describe "authorization" do
    context "when not logged in" do
      before { allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil) }

      it "redirects to login" do
        get host_venues_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "when regular user (not host)" do
      before { login_as(regular_user) }

      it "denies access to index" do
        get host_venues_path
        expect(response).to redirect_to(mainpage_path)
      end

      it "denies access to create" do
        post host_venues_path, params: { venue: { name: "Test" } }
        expect(response).to redirect_to(mainpage_path)
      end
    end
  end
end
