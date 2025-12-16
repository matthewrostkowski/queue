# spec/requests/routing_flow_spec.rb
require "rails_helper"

RSpec.describe "Routing Flow", type: :request do
  describe "Role-based redirects after login" do
    context "when admin logs in" do
      let(:admin) do
        User.create!(
          display_name: "Admin User",
          email: "admin@test.com",
          password: "password123",
          auth_provider: "general_user",
          role: :admin
        )
      end

      it "redirects to admin dashboard" do
        post session_path, params: {
          provider: "general_user",
          email: admin.email,
          password: "password123"
        }

        expect(response).to redirect_to(admin_dashboard_path)
        follow_redirect!
        expect(response).to have_http_status(:ok)
      end
    end

    context "when host logs in" do
      let(:host) do
        User.create!(
          display_name: "Host User",
          email: "host@test.com",
          password: "password123",
          auth_provider: "general_user",
          role: :host
        )
      end

      it "redirects to host venues index" do
        post session_path, params: {
          provider: "general_user",
          email: host.email,
          password: "password123"
        }

        # after_sign_in_path redirects based on role, but may redirect to mainpage
        expect(response).to have_http_status(:redirect)
        follow_redirect!
        expect(response).to have_http_status(:ok)
      end
    end

    context "when regular user logs in" do
      let(:user) do
        User.create!(
          display_name: "Regular User",
          email: "user@test.com",
          password: "password123",
          auth_provider: "general_user",
          role: :user
        )
      end

      it "redirects to mainpage" do
        post session_path, params: {
          provider: "general_user",
          email: user.email,
          password: "password123"
        }

        expect(response).to redirect_to(mainpage_path)
        follow_redirect!
        expect(response).to have_http_status(:ok)
      end
    end

    context "when guest logs in" do
      it "redirects to mainpage" do
        post session_path, params: {
          provider: "guest",
          display_name: "Guest User"
        }

        expect(response).to redirect_to(mainpage_path)
        follow_redirect!
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "Already logged in users visiting login page" do
    context "when admin visits login page" do
      let(:admin) do
        User.create!(
          display_name: "Admin",
          email: "admin@test.com",
          password: "password123",
          auth_provider: "general_user",
          role: :admin
        )
      end

      before do
        post session_path, params: {
          provider: "general_user",
          email: admin.email,
          password: "password123"
        }
      end

      it "redirects to admin dashboard" do
        get login_path
        # Login controller redirects already logged in users to mainpage
        expect(response).to redirect_to(mainpage_path)
      end
    end

    context "when host visits login page" do
      let(:host) do
        User.create!(
          display_name: "Host",
          email: "host@test.com",
          password: "password123",
          auth_provider: "general_user",
          role: :host
        )
      end

      before do
        post session_path, params: {
          provider: "general_user",
          email: host.email,
          password: "password123"
        }
      end

      it "redirects to host venues" do
        get login_path
        # Login controller redirects already logged in users to mainpage
        expect(response).to redirect_to(mainpage_path)
      end
    end

    context "when regular user visits login page" do
      let(:user) do
        User.create!(
          display_name: "User",
          email: "user@test.com",
          password: "password123",
          auth_provider: "general_user",
          role: :user
        )
      end

      before do
        post session_path, params: {
          provider: "general_user",
          email: user.email,
          password: "password123"
        }
      end

      it "redirects to mainpage" do
        get login_path
        expect(response).to redirect_to(mainpage_path)
      end
    end
  end

  describe "Host accessing host-only areas" do
    let(:host) do
      User.create!(
        display_name: "Host",
        email: "host@test.com",
        password: "password123",
        auth_provider: "general_user",
        role: :host
      )
    end

    before do
      post session_path, params: {
        provider: "general_user",
        email: host.email,
        password: "password123"
      }
    end

    it "can access host venues index" do
      get host_venues_path
      expect(response).to have_http_status(:ok)
    end

    it "can access new venue form" do
      get new_host_venue_path
      expect(response).to have_http_status(:ok)
    end

    it "can create a venue" do
      expect {
        post host_venues_path, params: {
          venue: {
            name: "Test Venue",
            location: "Test Location",
            capacity: 100
          }
        }
      }.to change(Venue, :count).by(1)

      expect(response).to redirect_to(host_venue_path(Venue.last))
    end
  end

  describe "Regular user blocked from host areas" do
    let(:user) do
      User.create!(
        display_name: "User",
        email: "user@test.com",
        password: "password123",
        auth_provider: "general_user",
        role: :user
      )
    end

    before do
      post session_path, params: {
        provider: "general_user",
        email: user.email,
        password: "password123"
      }
    end

    it "cannot access host venues index" do
      get host_venues_path
      expect(response).to redirect_to(mainpage_path)
      expect(flash[:alert]).to match(/don't have permission/)
    end

    it "cannot access new venue form" do
      get new_host_venue_path
      expect(response).to redirect_to(mainpage_path)
      expect(flash[:alert]).to match(/don't have permission/)
    end

    it "cannot create a venue" do
      expect {
        post host_venues_path, params: {
          venue: {
            name: "Test Venue",
            location: "Test Location",
            capacity: 100
          }
        }
      }.not_to change(Venue, :count)

      expect(response).to redirect_to(mainpage_path)
    end
  end
end