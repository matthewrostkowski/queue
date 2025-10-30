require 'rails_helper'

RSpec.describe "Venues", type: :request do
  let(:user) { User.create!(display_name: 'TestUser', auth_provider: 'guest') }
  let(:venue) { Venue.create!(name: 'Test Venue', location: 'Test Location', capacity: 100) }
  
  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
  end

  describe "venue model integration" do
    it "can create venues with all attributes" do
      expect(venue.name).to eq('Test Venue')
      expect(venue.location).to eq('Test Location')
      expect(venue.capacity).to eq(100)
    end

    it "can have queue sessions" do
      session = QueueSession.create!(venue: venue, is_active: true)
      expect(venue.queue_sessions).to include(session)
    end
  end
end
