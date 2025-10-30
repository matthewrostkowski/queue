require 'rails_helper'

RSpec.describe "Scan", type: :request do
  let(:user) { User.create!(display_name: 'TestUser', auth_provider: 'guest') }
  
  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
  end

  describe "GET /scan" do
    it "returns http success" do
      get scan_path
      expect(response).to have_http_status(:success)
    end

    it "displays scan interface" do
      get scan_path
      expect(response.body).to include('Scan')
    end
  end
end
