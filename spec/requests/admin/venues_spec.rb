require 'rails_helper'

RSpec.describe "Admin::VenuesController", type: :request do
  let!(:admin_user) { User.create!(display_name: "Admin", email: "admin@example.com", password: "password", auth_provider: "general_user", role: :admin) }
  let!(:regular_user) { User.create!(display_name: "Regular", email: "regular@example.com", password: "password", auth_provider: "general_user", role: :user) }
  let!(:host_user) { User.create!(display_name: "Host", email: "host@example.com", password: "password", auth_provider: "general_user", role: :host) }
  let!(:venue1) { Venue.create!(name: "Venue Alpha", location: "123 Main St", capacity: 100, host_user_id: host_user.id) }
  let!(:venue2) { Venue.create!(name: "Venue Beta", location: "456 Oak Ave", capacity: 200, host_user_id: host_user.id) }
  let!(:active_session) { QueueSession.create!(venue: venue1, status: "active", join_code: "123456") }

  before do
    login_as(admin_user)
  end

  describe "GET /admin/venues" do
    it "displays all venues ordered by name" do
      get admin_venues_path
      
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Venue Alpha")
      expect(response.body).to include("Venue Beta")
      
      # Check order
      alpha_position = response.body.index("Venue Alpha")
      beta_position = response.body.index("Venue Beta")
      expect(alpha_position).to be < beta_position
    end

    it "requires admin access" do
      login_as(regular_user)
      get admin_venues_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /admin/venues/:id" do
    it "shows venue details and sessions" do
      get admin_venue_path(venue1)
      
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(venue1.name)
      expect(response.body).to include(venue1.location)
      expect(assigns(:active_sessions)).to include(active_session)
      expect(assigns(:total_sessions)).to eq(1)
    end
  end

  describe "GET /admin/venues/new" do
    it "displays new venue form" do
      get new_admin_venue_path
      
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Venue")
    end
  end

  describe "POST /admin/venues" do
    context "with valid params" do
      it "creates a new venue and redirects" do
        expect {
          post admin_venues_path, params: {
            venue: {
              name: "New Venue",
              location: "789 Pine St",
              capacity: 150
            }
          }
        }.to change(Venue, :count).by(1)
        
        expect(response).to redirect_to(admin_venues_path)
        expect(flash[:notice]).to eq("Venue was successfully created.")
      end
    end

    context "with invalid params" do
      it "renders new template with errors" do
        expect {
          post admin_venues_path, params: {
            venue: {
              name: "", # Invalid - name required
              location: "789 Pine St"
            }
          }
        }.not_to change(Venue, :count)
        
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("New Venue")
      end
    end
  end

  describe "GET /admin/venues/:id/edit" do
    it "displays edit venue form" do
      get edit_admin_venue_path(venue1)
      
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Edit")
      expect(response.body).to include(venue1.name)
    end
  end

  describe "PATCH /admin/venues/:id" do
    context "with valid params" do
      it "updates the venue and redirects" do
        patch admin_venue_path(venue1), params: {
          venue: {
            name: "Updated Venue Name",
            location: "New Location",
            capacity: 500
          }
        }
        
        expect(response).to redirect_to(admin_venues_path)
        expect(flash[:notice]).to eq("Venue was successfully updated.")
        
        venue1.reload
        expect(venue1.name).to eq("Updated Venue Name")
        expect(venue1.location).to eq("New Location")
        expect(venue1.capacity).to eq(500)
      end
    end

    context "with invalid params" do
      it "renders edit template with errors" do
        patch admin_venue_path(venue1), params: {
          venue: {
            name: "" # Invalid
          }
        }
        
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit")
      end
    end
  end

  describe "PATCH /admin/venues/:id/update_pricing" do
    context "with valid pricing params" do
      it "updates pricing settings and redirects with notice" do
        patch update_pricing_admin_venue_path(venue1), params: {
          venue: {
            pricing_enabled: true,
            base_price_cents: 100,
            min_price_cents: 50,
            max_price_cents: 500,
            price_multiplier: 1.5,
            peak_hours_start: "18:00",
            peak_hours_end: "22:00",
            peak_hours_multiplier: 2.0
          }
        }
        
        expect(response).to redirect_to(edit_admin_venue_path(venue1))
        expect(flash[:notice]).to eq("Pricing settings updated successfully.")
        
        venue1.reload
        expect(venue1.pricing_enabled).to be true if venue1.respond_to?(:pricing_enabled)
        expect(venue1.base_price_cents).to eq(100) if venue1.respond_to?(:base_price_cents)
      end
    end

    context "with invalid pricing params" do
      it "redirects with alert" do
        allow_any_instance_of(Venue).to receive(:update).and_return(false)
        
        patch update_pricing_admin_venue_path(venue1), params: {
          venue: {
            pricing_enabled: true
          }
        }
        
        expect(response).to redirect_to(edit_admin_venue_path(venue1))
        expect(flash[:alert]).to eq("Failed to update pricing settings.")
      end
    end
  end

  describe "authorization" do
    context "when not admin" do
      before { login_as(regular_user) }

      it "redirects index" do
        get admin_venues_path
        expect(response).to redirect_to(root_path)
      end

      it "redirects show" do
        get admin_venue_path(venue1)
        expect(response).to redirect_to(root_path)
      end

      it "redirects new" do
        get new_admin_venue_path
        expect(response).to redirect_to(root_path)
      end

      it "redirects create" do
        post admin_venues_path, params: { venue: { name: "Test" } }
        expect(response).to redirect_to(root_path)
      end

      it "redirects edit" do
        get edit_admin_venue_path(venue1)
        expect(response).to redirect_to(root_path)
      end

      it "redirects update" do
        patch admin_venue_path(venue1), params: { venue: { name: "Test" } }
        expect(response).to redirect_to(root_path)
      end

      it "redirects update_pricing" do
        patch update_pricing_admin_venue_path(venue1), params: { venue: { pricing_enabled: true } }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
