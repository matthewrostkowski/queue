require 'rails_helper'

RSpec.describe "Search", type: :request do
  let(:user) { User.create!(display_name: 'TestUser', auth_provider: 'guest') }
  
  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
  end

  describe "GET /search" do
    it "returns http success" do
      get search_path
      expect(response).to have_http_status(:success)
    end

    it "displays search form" do
      get search_path
      expect(response.body).to include('Search')
    end

    it "shows search results when query provided" do
      get search_path, params: { q: 'test' }
      expect(response).to have_http_status(:success)
    end
  end
end
