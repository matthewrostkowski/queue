require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  describe "POST /session" do
    context "with JSON request" do
      it "creates/returns a user" do
        post "/session", params: { provider: 'guest', display_name: 'Matt' }, as: :json
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['display_name']).to eq('Matt')
        expect(body['provider']).to eq('guest')
      end
    end

    context "with HTML request" do
      it "creates user and redirects to mainpage" do
        post "/session", params: { provider: 'guest', display_name: 'Matt' }
        expect(response).to redirect_to(mainpage_path)
        expect(User.last.display_name).to eq('Matt')
      end
    end
  end

  describe "DELETE /logout" do
    it "clears session and redirects to login" do
      post "/session", params: { provider: 'guest', display_name: 'TestUser' }
      delete "/logout"
      expect(response).to redirect_to(login_path)
    end
  end
end
