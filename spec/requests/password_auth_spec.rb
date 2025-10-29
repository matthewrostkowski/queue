require "rails_helper"

RSpec.describe "Email/Password Auth", type: :request do
  describe "POST /users (sign up)" do
    it "creates a general_user and logs in" do
      post "/users", params: { user: { email: "user@example.com",
                                       password: "12345678",
                                       password_confirmation: "12345678",
                                       display_name: "UserX" } }
      expect(response).to redirect_to(mainpage_path)
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /session (sign in)" do
    let!(:user) do
      User.create!(auth_provider: "general_user",
                   email: "user@example.com",
                   password: "12345678", password_confirmation: "12345678",
                   display_name: "UserX")
    end

    it "logs in with correct credentials" do
      post "/session", params: { provider: "general_user", email: "user@example.com", password: "12345678" }
      expect(response).to redirect_to(mainpage_path)
    end

    it "rejects invalid password" do
      post "/session", params: { provider: "general_user", email: "user@example.com", password: "oops" }
      expect(response).to redirect_to(login_path)
    end
  end
end
