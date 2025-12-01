require 'rails_helper'

RSpec.describe "Scan", type: :request do
  let(:user) { 
    User.create!(
      display_name: 'TestUser',
      auth_provider: 'general_user',
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
  }

  let(:host_user) {
    User.create!(
      display_name: 'Host User',
      auth_provider: 'general_user',
      email: 'host@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      role: 'host'
    )
  }

  let(:venue) {
    Venue.create!(
      name: 'Test Venue',
      host_user_id: host_user.id,
      venue_code: '123456'
    )
  }
  
  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
  end

  describe "GET /scan" do
    it "returns http success" do
      get scan_path
      expect(response).to have_http_status(:success)
    end

    it "displays scan interface" do
      get scan_path
      expect(response.body).to include('Scan')
    end
  end

  describe "POST /scan (join_by_code)" do
    context "with venue code" do
      context "when venue has active session" do
        let!(:active_session) {
          venue.queue_sessions.create!(
            status: 'active',
            started_at: Time.current,
            join_code: '999999'
          )
        }

        it "joins venue's active session successfully" do
          post scan_path, params: { join_code: venue.venue_code }
          
          expect(response).to redirect_to(queue_path)
          expect(flash[:notice]).to include("Welcome to #{venue.name}!")
        end

        it "sets the current queue session" do
          post scan_path, params: { join_code: venue.venue_code }
          
          expect(session[:current_queue_session_id]).to eq(active_session.id)
        end
      end

      context "when venue has no active session" do
        it "shows appropriate error message" do
          post scan_path, params: { join_code: venue.venue_code }
          
          expect(response).to have_http_status(:success)
          expect(response.body).to include("#{venue.name} is not currently accepting song requests")
        end
      end

      it "handles venue code in 'code' parameter" do
        active_session = venue.queue_sessions.create!(
          status: 'active',
          started_at: Time.current,
          join_code: '888888'
        )

        post scan_path, params: { code: venue.venue_code }
        
        expect(response).to redirect_to(queue_path)
        expect(session[:current_queue_session_id]).to eq(active_session.id)
      end
    end

    context "with session code" do
      let!(:active_session) {
        venue.queue_sessions.create!(
          status: 'active',
          started_at: Time.current,
          join_code: '777777'
        )
      }

      it "joins session successfully" do
        post scan_path, params: { join_code: active_session.join_code }
        
        expect(response).to redirect_to(queue_path)
        expect(flash[:notice]).to include("Welcome to #{venue.name}!")
        expect(session[:current_queue_session_id]).to eq(active_session.id)
      end

      it "does not join ended session" do
        ended_session = venue.queue_sessions.create!(
          status: 'ended',
          started_at: 1.hour.ago,
          ended_at: 30.minutes.ago,
          join_code: '666666'
        )

        post scan_path, params: { join_code: ended_session.join_code }
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Code not found or session is no longer active")
      end
    end

    context "with invalid code" do
      it "rejects code with wrong format" do
        post scan_path, params: { join_code: 'ABC123' }
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Invalid code format")
      end

      it "rejects too short code" do
        post scan_path, params: { join_code: '12345' }
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Invalid code format")
      end

      it "rejects non-existent code" do
        post scan_path, params: { join_code: '000000' }
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Code not found")
      end
    end

    context "error handling" do
      it "handles database errors gracefully" do
        allow(VenueCodeGenerator).to receive(:find_by_code).and_raise(ActiveRecord::RecordNotFound)
        
        post scan_path, params: { join_code: '123456' }
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include("An error occurred")
      end
    end
  end

  describe "POST /join (backwards compatibility)" do
    it "handles join endpoint same as scan" do
      active_session = venue.queue_sessions.create!(
        status: 'active',
        started_at: Time.current,
        join_code: '555555'
      )

      post join_path, params: { join_code: venue.venue_code }
      
      expect(response).to redirect_to(queue_path)
      expect(session[:current_queue_session_id]).to eq(active_session.id)
    end
  end
end
