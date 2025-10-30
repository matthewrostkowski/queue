require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  it "POST /session creates/returns a user" do
    post "/session", params: { provider: 'guest', display_name: 'Matt' }
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body['display_name']).to eq('Matt')
  end
end
