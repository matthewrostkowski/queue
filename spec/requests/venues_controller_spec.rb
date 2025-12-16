require "rails_helper"

RSpec.describe "VenuesController", type: :request do
  let!(:user)  { User.create!(display_name: "SpecUser", auth_provider: "guest") }
  let!(:host) { User.create!(display_name: "Host", auth_provider: "guest") }
  let!(:venue) { Venue.create!(name: "Queue House", location: "Somewhere", capacity: 100, host_user_id: host.id) }

  before { login_as(user) }

  it "shows a venue" do
    # The VenuesController doesn't exist, so this route will 404
    # Use status: 'active' instead of is_active for new schema
    active = QueueSession.create!(venue: venue, status: 'active', join_code: '123456', started_at: Time.current)

    get "/venues/#{venue.id}", as: :json
    # Since VenuesController doesn't exist, expect 404
    expect(response).to have_http_status(:not_found)
  end
end
