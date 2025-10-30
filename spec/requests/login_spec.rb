require 'rails_helper'

RSpec.describe "Login", type: :request do
  describe "GET /login" do
    it "returns http success" do
      get login_path
      expect(response).to have_http_status(:success)
    end

    it "displays login form" do
      get login_path
      expect(response.body).to include('Sign in')
      expect(response.body).to include('Continue as Guest')
    end
  end

  describe "GET /" do
    it "redirects to login" do
      get root_path
      expect(response).to redirect_to(login_path)
    end
  end
end
