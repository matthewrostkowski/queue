require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  let!(:admin) do
    User.create!(display_name: "Admin", email: "admin@example.com", password: "password", auth_provider: "general_user", role: :admin)
  end

  before do
    # stub auth
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
  end

  it "shows counts for users, venues, active sessions, and songs" do
    # seed some data
    Venue.create!(name: "V1")
    s = QueueSession.create!(venue: Venue.first, is_active: true, is_playing: true, playback_started_at: 10.minutes.ago, access_code: "CODE1")
    Song.create!(title: "T1", artist: "A1")
    Song.create!(title: "T2", artist: "A2")
    User.create!(display_name: "U2", email: "u2@example.com", password: "password", auth_provider: "local", role: :user)

    get admin_dashboard_path
    expect(response).to have_http_status(:ok)

    expect(response.body).to include("Total Users")
    expect(response.body).to include(User.count.to_s)

    expect(response.body).to include("Total Venues")
    expect(response.body).to include(Venue.count.to_s)

    expect(response.body).to include("Active Sessions")
    expect(response.body).to include(QueueSession.where(is_active: true).count.to_s)

    expect(response.body).to include("Total Songs")
    expect(response.body).to include(Song.count.to_s)
  end

  it "blocks non-admin users" do
    non_admin = User.create!(display_name: "U1", email: "u1@example.com", password: "password", auth_provider: "local", role: :user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(non_admin)

    get admin_dashboard_path
    expect(response).to redirect_to(mainpage_path)
  end
end
