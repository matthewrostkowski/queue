require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  it "POST /session creates/returns a user (Basic check)" do
    post "/session", params: { provider: 'guest', display_name: 'Matt' }, as: :json
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body['display_name']).to eq('Matt')
  end
  
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
  
  it "creates a user with guest provider" do
    expect {
      post "/session", params: { provider: 'guest', display_name: 'Test' }, as: :json
    }.to change { User.count }.by(1)
  end
  
  it "returns user data as JSON" do
    post "/session", params: { provider: 'guest', display_name: 'Bob' }, as: :json
    body = JSON.parse(response.body)
    expect(body).to have_key('display_name')
    expect(body).to have_key('auth_provider')
  end
end
