# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Authentication", type: :request do
  it "redirects to /login when visiting protected pages without session" do
    %w[/mainpage /search /profile /scan].each do |path|
      get path
      expect(response).to redirect_to(login_path), "expected #{path} to redirect to /login"
    end
  end

  it "allows access after login" do
    post "/session", params: { provider: "guest", display_name: "After Login" }
    get "/mainpage"
    expect(response).to have_http_status(:ok)
  end

  it "returns 401 for JSON when unauthenticated" do
    get "/search", as: :json
    expect(response).to have_http_status(:unauthorized)
  end
end
