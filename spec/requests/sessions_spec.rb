# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Sessions", type: :request do
  describe "POST /session (HTML)" do
    it "creates a guest session and redirects to mainpage" do
      post "/session", params: { provider: "guest", display_name: "Guest RSpec" }
      expect(response).to redirect_to(mainpage_path)
      follow_redirect!
      expect(response.body).to include("Welcome")
      get "/mainpage"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /session (JSON)" do
    it "returns 200 with user payload" do
      post "/session", params: { provider: "guest", display_name: "Guest API" }, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to include("id", "display_name" => "Guest API", "provider" => "guest")
    end
  end

  describe "DELETE /logout" do
    it "clears session and redirects to login" do
      post "/session", params: { provider: "guest", display_name: "Someone" }
      get "/mainpage"
      expect(response).to have_http_status(:ok)

      delete "/logout"
      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(request.path).to eq("/login")
      expect(response.body).to include('data-testid="login-form"')
    end
  end
end
