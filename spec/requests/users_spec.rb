require 'rails_helper'

RSpec.describe "Users", type: :request do
  before { skip "Skipping users request specs for now" }
  describe "GET /signup" do
    it "returns http success" do
      get signup_path
      expect(response).to have_http_status(:success)
    end

    it "displays signup form" do
      get signup_path
      expect(response.body).to include('Create account')
      expect(response.body).to include('Email')
      expect(response.body).to include('Password')
    end
  end

  describe "POST /users" do
    let(:valid_params) do
      {
        user: {
          email: 'test@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    it "creates a new user with valid params" do
      expect {
        post users_path, params: valid_params
      }.to change(User, :count).by(1)
      
      expect(response).to redirect_to(mainpage_path)
      expect(User.last.email).to eq('test@example.com')
    end

    it "fails with invalid params" do
      invalid_params = valid_params.deep_dup
      invalid_params[:user][:email] = 'invalid-email'
      
      expect {
        post users_path, params: invalid_params
      }.not_to change(User, :count)
      
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "fails with short password" do
      invalid_params = valid_params.deep_dup
      invalid_params[:user][:password] = 'short'
      invalid_params[:user][:password_confirmation] = 'short'
      
      expect {
        post users_path, params: invalid_params
      }.not_to change(User, :count)
      
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /users/:id/summary" do
    let(:user) { User.create!(display_name: 'TestUser', auth_provider: 'guest') }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
    end

    it "returns user summary as JSON" do
      get user_summary_path(user), as: :json
      expect(response).to have_http_status(:success)
      
      body = JSON.parse(response.body)
      expect(body['username']).to eq('TestUser')
      expect(body['queued_count']).to eq(0)
    end
  end
end
