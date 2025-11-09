require "rails_helper"

RSpec.describe QueueItem, type: :model do
  let(:session) { QueueSession.create!(venue: Venue.create!(name: "Test Venue"), is_active: true) }

  it "is valid with title and artist" do
    qi = QueueItem.new(queue_session: session, title: "Song", artist: "Artist")
    expect(qi).to be_valid
  end

  it "orders by vote_score desc then created_at asc" do
    high = QueueItem.create!(queue_session: session, title: "High", artist: "A", vote_score: 3, created_at: 2.minutes.ago)
    low  = QueueItem.create!(queue_session: session, title: "Low",  artist: "A", vote_score: 1, created_at: 1.minute.ago)
    expect(QueueItem.by_votes).to eq([high, low])
  end
end
