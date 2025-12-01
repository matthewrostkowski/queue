require 'rails_helper'

RSpec.describe "HostVenuesController", type: :request do
  let!(:host_user) { User.create!(display_name: "Host", email: "host@example.com", password: "password", auth_provider: "general_user", role: :host) }
  let!(:regular_user) { User.create!(display_name: "Regular", email: "regular@example.com", password: "password", auth_provider: "general_user", role: :user) }
  let!(:venue) { Venue.create!(name: "Test Venue", location: "123 Main St", capacity: 100, host_user_id: host_user.id) }

  before do
    login_as(host_user)
  end

  describe "GET /host_venues" do
    it "displays venues for the current host" do
      get host_venues_path
      
      expect(response).to have_http_status(:ok)
      expect(assigns(:venues)).to include(venue)
    end

    it "requires host role" do
      login_as(regular_user)
      get host_venues_path
      expect(response).to redirect_to(mainpage_path)
    end
  end

  describe "GET /host_venues/new" do
    it "displays new venue form" do
      get new_host_venue_path
      
      expect(response).to have_http_status(:ok)
      expect(assigns(:venue)).to be_a_new(Venue)
    end
  end

  describe "POST /host_venues" do
    context "with valid params" do
      it "creates a new venue and redirects" do
        expect {
          post host_venues_path, params: {
            venue: {
              name: "New Venue",
              location: "456 Oak Ave",
              capacity: 200
            }
          }
        }.to change(Venue, :count).by(1)
        
        new_venue = Venue.last
        expect(new_venue.host_user_id).to eq(host_user.id)
        expect(response).to redirect_to(host_venue_path(new_venue))
        expect(flash[:notice]).to eq("Venue created successfully!")
      end
    end

    context "with invalid params" do
      it "renders new template with errors" do
        expect {
          post host_venues_path, params: {
            venue: { name: "" }
          }
        }.not_to change(Venue, :count)
        
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /host_venues/:id" do
    let!(:queue_session) { QueueSession.create!(venue: venue, status: "active", join_code: "123456") }

    it "displays venue details and sessions" do
      get host_venue_path(venue)
      
      expect(response).to have_http_status(:ok)
      expect(assigns(:venue)).to eq(venue)
      expect(assigns(:queue_sessions)).to include(queue_session)
      expect(assigns(:active_session)).to eq(queue_session)
    end
  end

  describe "GET /host_venues/:id/edit" do
    it "displays edit form" do
      get edit_host_venue_path(venue)
      
      expect(response).to have_http_status(:ok)
      expect(assigns(:venue)).to eq(venue)
    end
  end

  describe "PATCH /host_venues/:id" do
    context "with valid params" do
      it "updates the venue and redirects" do
        patch host_venue_path(venue), params: {
          venue: {
            name: "Updated Venue",
            location: "789 Pine St",
            capacity: 300
          }
        }
        
        expect(response).to redirect_to(host_venue_path(venue))
        expect(flash[:notice]).to eq("Venue updated successfully!")
        
        venue.reload
        expect(venue.name).to eq("Updated Venue")
      end
    end

    context "with invalid params" do
      it "renders edit template with errors" do
        patch host_venue_path(venue), params: {
          venue: { name: "" }
        }
        
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /host_venues/:id" do
    it "destroys the venue and redirects" do
      expect {
        delete host_venue_path(venue)
      }.to change(Venue, :count).by(-1)
      
      expect(response).to redirect_to(host_venues_path)
      expect(flash[:notice]).to eq("Venue deleted successfully!")
    end
  end

  describe "POST /host_venues/:venue_id/create_session" do
    context "when no active session exists" do
      it "creates a new session with join code" do
        expect {
          post host_venue_create_session_path(venue)
        }.to change(QueueSession, :count).by(1)
        
        new_session = QueueSession.last
        expect(new_session.venue).to eq(venue)
        expect(new_session.status).to eq("active")
        expect(new_session.join_code).to match(/^\d{6}$/)
        
        expect(response).to redirect_to(host_venue_path(venue))
        expect(flash[:notice]).to eq("Session started successfully!")
      end
    end

    context "when active session already exists" do
      let!(:existing_session) { QueueSession.create!(venue: venue, status: "active", join_code: "123456") }

      it "redirects with alert" do
        expect {
          post host_venue_create_session_path(venue)
        }.not_to change(QueueSession, :count)
        
        expect(response).to redirect_to(host_venue_path(venue))
        expect(flash[:alert]).to include("active session already exists")
      end
    end
  end

  describe "POST /host_venues/:venue_id/pause_session" do
    let!(:active_session) { QueueSession.create!(venue: venue, status: "active", join_code: "123456") }

    it "pauses the session" do
      allow_any_instance_of(HostVenuesController).to receive(:params).and_return(
        ActionController::Parameters.new(venue_id: venue.id, session_id: active_session.id)
      )
      
      post "/host_venues/#{venue.id}/pause_session", params: { session_id: active_session.id }
      
      active_session.reload
      expect(active_session.status).to eq("paused")
      expect(response).to redirect_to(host_venue_path(venue))
      expect(flash[:notice]).to eq("Session paused")
    end
  end

  describe "POST /host_venues/:venue_id/end_session" do
    let!(:active_session) { QueueSession.create!(venue: venue, status: "active", join_code: "123456") }

    it "ends the session" do
      allow_any_instance_of(HostVenuesController).to receive(:params).and_return(
        ActionController::Parameters.new(venue_id: venue.id, session_id: active_session.id)
      )
      
      post "/host_venues/#{venue.id}/end_session", params: { session_id: active_session.id }
      
      active_session.reload
      expect(active_session.status).to eq("ended")
      expect(response).to redirect_to(host_venue_path(venue))
      expect(flash[:notice]).to eq("Session ended")
    end
  end

  describe "POST /host_venues/:venue_id/regenerate_code" do
    let!(:active_session) { QueueSession.create!(venue: venue, status: "active", join_code: "123456") }

    it "regenerates the join code" do
      allow_any_instance_of(HostVenuesController).to receive(:params).and_return(
        ActionController::Parameters.new(venue_id: venue.id, session_id: active_session.id)
      )
      
      old_code = active_session.join_code
      
      post "/host_venues/#{venue.id}/regenerate_code", params: { session_id: active_session.id }
      
      active_session.reload
      expect(active_session.join_code).not_to eq(old_code)
      expect(active_session.join_code).to match(/^\d{6}$/)
      expect(response).to redirect_to(host_venue_path(venue))
      expect(flash[:notice]).to eq("Code regenerated")
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

      it "denies access to show" do
        get host_venue_path(venue)
        expect(response).to redirect_to(mainpage_path)
      end
    end
  end
end
