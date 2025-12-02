require 'rails_helper'

RSpec.describe "Admin::BaseController", type: :request do
  let!(:admin_user) { User.create!(display_name: "Admin", email: "admin@example.com", password: "password", auth_provider: "general_user", role: :admin) }
  let!(:regular_user) { User.create!(display_name: "Regular", email: "regular@example.com", password: "password", auth_provider: "general_user", role: :user) }
  let!(:host_user) { User.create!(display_name: "Host", email: "host@example.com", password: "password", auth_provider: "general_user", role: :host) }

  describe "admin access control" do
    context "when user is admin" do
      before do
        login_as(admin_user)
      end

      it "allows access to admin dashboard" do
        get admin_dashboard_path
        expect(response).to have_http_status(:ok)
      end

      it "allows access to admin users" do
        get admin_users_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when user is not admin (regular user)" do
      before do
        login_as(regular_user)
      end

      it "redirects to mainpage with alert for dashboard" do
        get admin_dashboard_path
        expect(response).to redirect_to(mainpage_path)
        expect(flash[:alert]).to include("Admin access required")
      end

      it "redirects to mainpage with alert for users" do
        get admin_users_path
        expect(response).to redirect_to(mainpage_path)
        expect(flash[:alert]).to include("Admin access required")
      end
    end

    context "when user is host (not admin)" do
      before do
        login_as(host_user)
      end

      it "redirects to mainpage with alert" do
        get admin_dashboard_path
        expect(response).to redirect_to(mainpage_path)
        expect(flash[:alert]).to include("Admin access required")
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get admin_dashboard_path
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to include("Please sign in")
      end
    end
  end
end
