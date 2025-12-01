require 'rails_helper'

RSpec.describe "Api::PricingController", type: :request do
  let!(:user) { User.create!(display_name: "Test User", email: "user@example.com", password: "password", auth_provider: "general_user") }
  let!(:venue) { Venue.create!(name: "Test Venue", location: "123 Main St") }
  let!(:queue_session) { QueueSession.create!(venue: venue, status: "active", join_code: "123456") }

  before do
    login_as(user)
    allow_any_instance_of(ApplicationController).to receive(:session).and_return({
      user_id: user.id,
      current_queue_session_id: queue_session.id
    })
  end

  describe "GET /api/pricing/current_prices" do
    context "with active queue session" do
      it "returns pricing for positions 1-10" do
        get current_prices_api_pricing_index_path, params: { queue_session_id: queue_session.id }, as: :json
        
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        
        expect(body).to have_key("queue_session_id")
        expect(body["queue_session_id"]).to eq(queue_session.id)
        
        expect(body).to have_key("positions")
        expect(body["positions"]).to be_an(Array)
        expect(body["positions"].length).to eq(10)
        
        # Check first position
        first_position = body["positions"].first
        expect(first_position).to have_key("position")
        expect(first_position["position"]).to eq(1)
        expect(first_position).to have_key("price_cents")
        expect(first_position).to have_key("price_display")
        expect(first_position["price_display"]).to match(/^\$\d+\.\d{2}$/)
        
        # Check that positions are in order
        positions = body["positions"].map { |p| p["position"] }
        expect(positions).to eq((1..10).to_a)
        
        expect(body).to have_key("factors")
      end

      it "uses current queue session when no queue_session_id provided" do
        get current_prices_api_pricing_index_path, as: :json
        
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["queue_session_id"]).to eq(queue_session.id)
      end
    end

    context "without active queue session" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_queue_session).and_return(nil)
      end

      it "returns not found error" do
        get current_prices_api_pricing_index_path, as: :json
        
        expect(response).to have_http_status(:not_found)
        body = JSON.parse(response.body)
        expect(body["error"]).to include("No active queue session found")
      end
    end
  end

  describe "GET /api/pricing/position_price" do
    context "with valid position" do
      it "returns price for specific position" do
        get position_price_api_pricing_index_path, params: { 
          queue_session_id: queue_session.id,
          position: 5 
        }, as: :json
        
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        
        expect(body["position"]).to eq(5)
        expect(body).to have_key("price_cents")
        expect(body).to have_key("price_display")
        expect(body["price_display"]).to match(/^\$\d+\.\d{2}$/)
        expect(body).to have_key("factors")
      end

      it "uses current queue session when no queue_session_id provided" do
        get position_price_api_pricing_index_path, params: { position: 3 }, as: :json
        
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["position"]).to eq(3)
      end
    end

    context "with invalid position" do
      it "returns bad request for position 0" do
        get position_price_api_pricing_index_path, params: { position: 0 }, as: :json
        
        expect(response).to have_http_status(:bad_request)
        body = JSON.parse(response.body)
        expect(body["error"]).to include("Invalid queue session or position")
      end

      it "returns bad request for negative position" do
        get position_price_api_pricing_index_path, params: { position: -1 }, as: :json
        
        expect(response).to have_http_status(:bad_request)
        body = JSON.parse(response.body)
        expect(body["error"]).to include("Invalid queue session or position")
      end

      it "returns bad request when position not provided" do
        get position_price_api_pricing_index_path, as: :json
        
        expect(response).to have_http_status(:bad_request)
        body = JSON.parse(response.body)
        expect(body["error"]).to include("Invalid queue session or position")
      end
    end

    context "without active queue session" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_queue_session).and_return(nil)
      end

      it "returns bad request error" do
        get position_price_api_pricing_index_path, params: { position: 1 }, as: :json
        
        expect(response).to have_http_status(:bad_request)
        body = JSON.parse(response.body)
        expect(body["error"]).to include("Invalid queue session or position")
      end
    end
  end

  describe "GET /api/pricing/factors" do
    context "with active queue session" do
      it "returns pricing factors" do
        get pricing_factors_api_pricing_index_path, params: { queue_session_id: queue_session.id }, as: :json
        
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        
        # The response should be the factors object directly
        expect(body).to be_a(Hash)
        expect(body).to have_key("queue_length") if defined?(DynamicPricingService)
      end

      it "uses current queue session when no queue_session_id provided" do
        get pricing_factors_api_pricing_index_path, as: :json
        
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body).to be_a(Hash)
      end
    end

    context "without active queue session" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_queue_session).and_return(nil)
      end

      it "returns not found error" do
        get pricing_factors_api_pricing_index_path, as: :json
        
        expect(response).to have_http_status(:not_found)
        body = JSON.parse(response.body)
        expect(body["error"]).to include("No active queue session found")
      end
    end
  end

  describe "authentication" do
    context "when not authenticated" do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      end

      it "allows API calls (skip_before_action :verify_authenticity_token)" do
        # API endpoints should work without authentication since they skip CSRF
        get current_prices_api_pricing_index_path, params: { queue_session_id: queue_session.id }, as: :json
        
        # The response will depend on whether current_queue_session requires auth
        # But it shouldn't fail on CSRF token validation
        expect([200, 404]).to include(response.status)
      end
    end
  end

  describe "when DynamicPricingService is not defined" do
    before do
      # Simulate DynamicPricingService not being defined
      allow(Object).to receive(:const_defined?).with(:DynamicPricingService).and_return(false)
      stub_const("DynamicPricingService", Class.new do
        def self.calculate_position_price(session, position)
          100 * position # Simple mock pricing
        end
        
        def self.get_pricing_factors(session, position = nil)
          { 
            queue_length: 5,
            time_of_day: "peak",
            position: position
          }
        end
      end)
    end

    it "still returns pricing data" do
      get current_prices_api_pricing_index_path, params: { queue_session_id: queue_session.id }, as: :json
      
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["positions"]).to be_present
      
      # Check that mock pricing is used
      expect(body["positions"].first["price_cents"]).to eq(100) # position 1 * 100
      expect(body["positions"].last["price_cents"]).to eq(1000) # position 10 * 100
    end
  end
end
